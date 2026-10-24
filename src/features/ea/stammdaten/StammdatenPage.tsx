import { useId, useState, type FormEvent } from 'react'
import { CircleAlertIcon, PlusIcon, RotateCwIcon } from 'lucide-react'
import { useLoaderData, useRevalidator } from 'react-router-dom'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { saveMasterRow, type MasterInput, type MasterRow, type MasterTable, type StammdatenResult } from '@/features/ea/stammdaten/data'
import { MESSAGES, toMessage } from '@/lib/errors'

// T050 (US-EA-14): zwei Listen Referate und Gremien mit Bezeichnung, Reihenfolge, Status; Neu und Bearbeiten.
// Inaktive bleiben an vorhandenen Zuordnungen sichtbar, sind aber nicht neu wählbar (R38 AD).
export function StammdatenPage() {
  const { referate, gremien, failed } = useLoaderData() as StammdatenResult
  const revalidator = useRevalidator()

  return (
    <section className="flex flex-col gap-8">
      <h1 className="text-xl font-semibold">Referate und Gremien</h1>
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
        <>
          <MasterList table="ea_referate" title="Referate" newLabel="Referat anlegen" rows={referate} />
          <MasterList table="ea_gremien" title="Gremien" newLabel="Gremium anlegen" rows={gremien} />
        </>
      )}
    </section>
  )
}

type ListProps = { table: MasterTable; title: string; newLabel: string; rows: MasterRow[] }

function MasterList({ table, title, newLabel, rows }: ListProps) {
  const revalidator = useRevalidator()
  const [editing, setEditing] = useState<string | 'new' | null>(null)
  const nextOrder = rows.reduce((max, r) => Math.max(max, r.sort_order), 0) + 10

  function done() {
    setEditing(null)
    revalidator.revalidate()
  }

  return (
    <section aria-labelledby={`${table}-title`} className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 id={`${table}-title`} className="font-medium">
          {title}
        </h2>
        {editing !== 'new' && (
          <Button variant="outline" onClick={() => setEditing('new')}>
            <PlusIcon data-icon="inline-start" aria-hidden="true" />
            {newLabel}
          </Button>
        )}
      </div>

      {editing === 'new' && (
        <MasterForm
          table={table}
          id={null}
          initial={{ name: '', sort_order: nextOrder, is_active: true }}
          onCancel={() => setEditing(null)}
          onSaved={done}
        />
      )}

      {rows.length === 0 ? (
        <p className="text-sm text-muted-foreground">Noch keine Einträge.</p>
      ) : (
        <ul className="flex flex-col divide-y rounded-xl border">
          {rows.map((r) =>
            editing === r.id ? (
              <li key={r.id} className="p-3">
                <MasterForm table={table} id={r.id} initial={r} onCancel={() => setEditing(null)} onSaved={done} />
              </li>
            ) : (
              <li key={r.id} className="flex flex-wrap items-center justify-between gap-3 px-4 py-3">
                <div className="flex flex-wrap items-center gap-3">
                  <span className="font-medium">{r.name}</span>
                  <span className="text-sm text-muted-foreground tabular-nums">Reihenfolge {r.sort_order}</span>
                  {r.is_active ? (
                    <Badge className="bg-status-active-bg text-status-active">aktiv</Badge>
                  ) : (
                    <Badge className="bg-status-none-bg text-status-none">inaktiv</Badge>
                  )}
                </div>
                <Button variant="outline" size="sm" onClick={() => setEditing(r.id)} aria-label={`${r.name} bearbeiten`}>
                  Bearbeiten
                </Button>
              </li>
            ),
          )}
        </ul>
      )}
    </section>
  )
}

type FormProps = {
  table: MasterTable
  id: string | null
  initial: MasterInput
  onCancel: () => void
  onSaved: () => void
}

function MasterForm({ table, id, initial, onCancel, onSaved }: FormProps) {
  const fid = useId()
  const [name, setName] = useState(initial.name)
  const [order, setOrder] = useState(String(initial.sort_order))
  const [active, setActive] = useState(initial.is_active)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    if (!name.trim()) return setError(MESSAGES.nameRequiredSingle)
    const sortOrder = Number.parseInt(order, 10)
    if (!Number.isFinite(sortOrder)) return setError(MESSAGES.fieldRequired.replace('<Feld>', 'Reihenfolge'))
    setPending(true)
    try {
      const err = await saveMasterRow(table, id, { name, sort_order: sortOrder, is_active: active })
      if (err) return setError(toMessage(err).text)
      onSaved()
    } catch (caught) {
      setError(toMessage(caught).text)
    } finally {
      setPending(false)
    }
  }

  return (
    <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4 rounded-xl border p-4">
      <div className="grid gap-4 sm:grid-cols-[1fr_8rem]">
        <div className="flex flex-col gap-2">
          <Label htmlFor={`${fid}-name`}>Bezeichnung</Label>
          <Input id={`${fid}-name`} required value={name} onChange={(e) => setName(e.target.value)} autoComplete="off" />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor={`${fid}-order`}>Reihenfolge</Label>
          <Input
            id={`${fid}-order`}
            type="number"
            inputMode="numeric"
            step={1}
            required
            value={order}
            onChange={(e) => setOrder(e.target.value)}
          />
        </div>
      </div>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={active} onChange={(e) => setActive(e.target.checked)} className="size-4 accent-primary" />
        aktiv (in Zuordnungen neu wählbar)
      </label>

      {error && (
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {error}
        </p>
      )}

      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={pending}>
          {pending ? 'Speichern …' : 'Speichern'}
        </Button>
        <Button type="button" variant="outline" onClick={onCancel} disabled={pending}>
          Abbrechen
        </Button>
      </div>
    </form>
  )
}
