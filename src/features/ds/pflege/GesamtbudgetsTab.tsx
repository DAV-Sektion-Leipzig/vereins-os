import { useState } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useDsAccess } from '@/features/ds/access'
import type { Visibility } from '@/features/ds/budget/data'
import { euro } from '@/features/ds/budget/ui'
import type { GroupRow, ItemRow, PflegeData } from '@/features/ds/pflege/data'
import { useAction } from '@/features/ds/pflege/shared'
import { FormError, selectClassName } from '@/features/gr/shared/ui'

const VISIBILITY: Record<Visibility, string> = { referat: 'Referat', all: 'alle', none: 'ohne Referat' }

// US-FI-23 (R22): Sichtbarkeit und Referat je Gesamtbudget; Budgetposten einem anderen Gesamtbudget zuordnen (P8).
export function GesamtbudgetsTab({ data }: { data: PflegeData }) {
  if (data.groups.length === 0) return <p className="text-sm text-muted-foreground">Zuerst den Finanzplan einlesen.</p>
  const names = data.groups.map((g) => g.name)
  return (
    <div className="flex flex-col gap-3">
      <p className="text-sm text-muted-foreground">
        „Referat“: Referent:innen des Referats sehen die Einzelbuchungen und pflegen Hinweise und Umschichtungen. „alle“: alle mit
        Zugriff auf das Dashboard sehen die Einzelbuchungen. „ohne Referat“: nur Summen.
      </p>
      <datalist id="group-names">
        {names.map((n) => (
          <option key={n} value={n} />
        ))}
      </datalist>
      <ul className="flex flex-col gap-2">
        {data.groups.map((g) => (
          <GroupCard key={g.id} group={g} items={data.items.filter((i) => i.group_id === g.id)} />
        ))}
      </ul>
    </div>
  )
}

function GroupCard({ group, items }: { group: GroupRow; items: ItemRow[] }) {
  const { referate } = useDsAccess()
  const [visibility, setVisibility] = useState<Visibility>(group.visibility)
  const [referat, setReferat] = useState(group.referat_id ?? '')
  const [open, setOpen] = useState(false)
  const action = useAction()
  const changed = visibility !== group.visibility || (visibility === 'referat' && referat !== (group.referat_id ?? ''))

  async function save() {
    const res = await action.run('fi_budget_group_set', { p_group: group.id, p_visibility: visibility, p_referat: visibility === 'referat' ? referat || null : null })
    if (res !== null) toast.success(`„${group.name}“ gespeichert.`)
  }

  return (
    <li className="flex flex-col gap-2 rounded-xl border px-3 py-2.5">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
        <button type="button" className="min-w-0 flex-1 text-left" aria-expanded={open} onClick={() => setOpen(!open)}>
          <span className="font-medium">{group.name}</span>
          <span className="ml-2 text-sm text-muted-foreground">
            {items.length} Budgetposten · {euro(items.filter((i) => i.kind === 'expense').reduce((s, i) => s + Number(i.plan_decided ?? 0), 0))}
          </span>
        </button>
        <div className="flex flex-wrap items-center gap-2">
          <select aria-label={`Sichtbarkeit ${group.name}`} className={selectClassName} value={visibility} onChange={(e) => setVisibility(e.target.value as Visibility)}>
            {(Object.keys(VISIBILITY) as Visibility[]).map((v) => (
              <option key={v} value={v}>
                {VISIBILITY[v]}
              </option>
            ))}
          </select>
          {visibility === 'referat' && (
            <select aria-label={`Referat ${group.name}`} className={selectClassName} value={referat} onChange={(e) => setReferat(e.target.value)}>
              <option value="">Referat wählen</option>
              {referate.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.name}
                </option>
              ))}
            </select>
          )}
          <Button size="sm" onClick={save} disabled={!changed || action.pending}>
            Speichern
          </Button>
        </div>
      </div>
      <FormError text={action.error} />
      {open && (
        <ul className="flex flex-col gap-1.5 border-t pt-2">
          {items.map((i) => (
            <ItemMove key={i.id} item={i} />
          ))}
        </ul>
      )}
    </li>
  )
}

function ItemMove({ item }: { item: ItemRow }) {
  const [target, setTarget] = useState('')
  const action = useAction()
  return (
    <li className="flex flex-col gap-1 sm:flex-row sm:items-center sm:gap-3">
      <span className="min-w-0 flex-1 text-sm">
        {item.name} <span className="text-muted-foreground">· {item.kind === 'income' ? 'Einnahme' : 'Ausgabe'} · {euro(item.plan_decided)}</span>
      </span>
      <form
        className="flex items-center gap-2"
        onSubmit={async (e) => {
          e.preventDefault()
          if (target.trim() === '') return
          const res = await action.run('fi_budget_item_move', { p_item: item.id, p_group_name: target.trim() })
          if (res !== null) {
            toast.success(`„${item.name}“ gehört jetzt zu „${target.trim()}“.`)
            setTarget('')
          }
        }}
      >
        <Input
          list="group-names"
          aria-label={`Neues Gesamtbudget für ${item.name}`}
          placeholder="anderes Gesamtbudget"
          value={target}
          onChange={(e) => setTarget(e.target.value)}
          className="h-7 sm:w-52"
        />
        <Button type="submit" size="sm" variant="outline" disabled={action.pending || target.trim() === ''}>
          Verschieben
        </Button>
      </form>
      <FormError text={action.error} />
    </li>
  )
}
