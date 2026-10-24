import { useEffect, useState } from 'react'
import { PlusIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useGrAccess } from '@/features/gr/access'
import {
  applyGroupFilter,
  groupFilterHref,
  type GroupFilter,
  type GroupOverviewResult,
  type GroupOverviewRow,
} from '@/features/gr/gruppen/data'
import { HintBadge, LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { formatDate } from '@/lib/format'

const SEARCH_DELAY_MS = 300

// T025 (US-GR-02): Gruppenübersicht mit heutigen Trainingszeiten, aktiven Teilnahmen und Hinweiszählern
// („Teilnahme klären“, „Kein Notfallkontakt hinterlegt.“, „Aufnahme offen“); Suche, Referat, aufgelöst.
export function GruppenPage() {
  const { filter, rows, referate, failed } = useLoaderData() as GroupOverviewResult
  const { canEdit } = useGrAccess()
  const visible = applyGroupFilter(rows, filter)

  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Gruppen</h1>
        {canEdit && (
          <Button asChild>
            <Link to="/gr/gruppen/neu">
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              Gruppe anlegen
            </Link>
          </Button>
        )}
      </div>

      <FilterForm key={groupFilterHref({ ...filter, q: '' })} filter={filter} referate={referate} />

      {failed ? (
        <LoadFailed />
      ) : (
        <ResponsiveTable
          rows={visible}
          rowKey={(g) => g.id}
          columns={COLUMNS}
          card={(g) => <GroupCard group={g} />}
          empty="Keine Gruppen gefunden."
          caption="Gruppen"
        />
      )}
    </section>
  )
}

function FilterForm({ filter, referate }: { filter: GroupFilter; referate: GroupOverviewResult['referate'] }) {
  const navigate = useNavigate()
  const [q, setQ] = useState(filter.q)

  // Suche mit kurzer Verzögerung; Referat und „aufgelöst“ sofort (Filter bleiben in der URL)
  useEffect(() => {
    if (q.trim() === filter.q) return
    const timer = window.setTimeout(() => navigate(groupFilterHref({ ...filter, q: q.trim() }), { replace: true }), SEARCH_DELAY_MS)
    return () => window.clearTimeout(timer)
  }, [q, filter, navigate])

  const set = (patch: Partial<GroupFilter>) => navigate(groupFilterHref({ ...filter, q: q.trim(), ...patch }), { replace: true })
  const hasFilter = filter.q || filter.referat || filter.dissolved

  return (
    <form role="search" onSubmit={(e) => e.preventDefault()} className="flex flex-col gap-4 sm:flex-row sm:flex-wrap sm:items-end">
      <div className="flex flex-col gap-2 sm:w-64">
        <Label htmlFor="gr-search">Suche</Label>
        <Input
          id="gr-search"
          type="search"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Name der Gruppe"
          autoComplete="off"
        />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-referat">Referat</Label>
        <select id="gr-referat" value={filter.referat} onChange={(e) => set({ referat: e.target.value })} className={selectClassName}>
          <option value="">alle</option>
          {referate.map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
            </option>
          ))}
        </select>
      </div>
      <label className="flex h-8 items-center gap-2 text-sm">
        <input
          type="checkbox"
          checked={filter.dissolved}
          onChange={(e) => set({ dissolved: e.target.checked })}
          className="size-4 accent-primary"
        />
        aufgelöste Gruppen zeigen
      </label>
      {hasFilter && (
        <Button variant="ghost" asChild className="self-start sm:self-auto">
          <Link to="/gr" replace>
            Filter zurücksetzen
          </Link>
        </Button>
      )}
    </form>
  )
}

function GroupName({ group }: { group: GroupOverviewRow }) {
  return (
    <span className="flex flex-col gap-0.5">
      <Link to={`/gr/gruppen/${group.id}`} className="font-medium underline-offset-4 hover:underline">
        {group.name}
      </Link>
      {group.dissolved_on && <span className="text-sm text-muted-foreground">aufgelöst am {formatDate(group.dissolved_on)}</span>}
    </span>
  )
}

function TrainingTimes({ group }: { group: GroupOverviewRow }) {
  return group.training_times_today ? (
    <span>{group.training_times_today}</span>
  ) : (
    <span className="text-muted-foreground">Keine Trainingszeit</span>
  )
}

/** Hinweiszähler (R7, R17, Aufnahme offen); leer, wenn es nichts zu tun gibt. */
function Hints({ group }: { group: GroupOverviewRow }) {
  const hints = [
    group.clarify_count > 0 && `${group.clarify_count} × Teilnahme klären`,
    group.no_emergency_count > 0 && `${group.no_emergency_count} × kein Notfallkontakt`,
    group.pending_count > 0 && `${group.pending_count} × Aufnahme offen`,
  ].filter((h): h is string => Boolean(h))
  if (hints.length === 0) return <span className="text-muted-foreground">–</span>
  return (
    <span className="flex flex-wrap gap-1.5">
      {hints.map((h) => (
        <HintBadge key={h}>{h}</HintBadge>
      ))}
    </span>
  )
}

const COLUMNS: Column<GroupOverviewRow>[] = [
  { key: 'name', header: 'Gruppe', cell: (g) => <GroupName group={g} />, className: 'whitespace-normal' },
  { key: 'referat', header: 'Referat', cell: (g) => g.referat_name },
  { key: 'times', header: 'Trainingszeiten', cell: (g) => <TrainingTimes group={g} />, className: 'whitespace-normal' },
  { key: 'active', header: 'Teilnehmer:innen', cell: (g) => g.active_count, className: 'tabular-nums' },
  { key: 'hints', header: 'Hinweise', cell: (g) => <Hints group={g} />, className: 'whitespace-normal' },
  {
    key: 'open',
    header: <span className="sr-only">Aktion</span>,
    headerClassName: 'w-0',
    cell: (g) => (
      <Button variant="outline" asChild>
        <Link to={`/gr/gruppen/${g.id}`} aria-label={`${g.name} öffnen`}>
          Öffnen
        </Link>
      </Button>
    ),
  },
]

function GroupCard({ group }: { group: GroupOverviewRow }) {
  return (
    <>
      <div className="flex flex-col gap-1">
        <GroupName group={group} />
        <span className="text-sm text-muted-foreground">{group.referat_name}</span>
        <span className="text-sm">
          <TrainingTimes group={group} />
        </span>
        <span className="text-sm">
          {group.active_count} {group.active_count === 1 ? 'Teilnehmer:in' : 'Teilnehmer:innen'}
        </span>
        <Hints group={group} />
      </div>
      <Button variant="outline" asChild className="h-11 self-start sm:h-8">
        <Link to={`/gr/gruppen/${group.id}`} aria-label={`${group.name} öffnen`}>
          Öffnen
        </Link>
      </Button>
    </>
  )
}
