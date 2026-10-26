import { useState } from 'react'
import { PlusIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { Pagination } from '@/components/Pagination'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useEzAccess } from '@/features/ez/access'
import { formatEventDate } from '@/features/ez/dates'
import { KIND_LABELS, KINDS, presentSummary, type EventKind } from '@/features/ez/labels'
import {
  eventFilterHref,
  halfYearOptions,
  type EventFilter,
  type EventListResult,
  type EventRow,
} from '@/features/ez/liste/data'
import { SettledBadge } from '@/features/ez/shared/SettledBadge'
import { LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { cn } from '@/lib/utils'

// T021 (US-EZ-14, -15): Einsätze mit Filtern (Zeitraum, Referat, Gruppe, Einsatzart), 50 je Seite, mobil als Karten;
// abgesagte Einsätze mit durchgestrichenem Titel und ausgegrauter Anzahl (R22).
export function EinsaetzePage() {
  const { filter, page, rows, total, referate, groups, failed } = useLoaderData() as EventListResult
  const { canEdit } = useEzAccess()

  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Einsätze</h1>
        {canEdit && (
          <Button asChild>
            <Link to="/ez/neu">
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              Neuer Einsatz
            </Link>
          </Button>
        )}
      </div>

      <FilterForm key={eventFilterHref(filter)} filter={filter} referate={referate} groups={groups} />

      {failed ? (
        <LoadFailed />
      ) : (
        <>
          <ResponsiveTable
            rows={rows}
            rowKey={(e) => e.id}
            columns={COLUMNS}
            card={(e) => <EventCard event={e} />}
            empty="Keine Einsätze gefunden."
            caption="Einsätze"
          />
          <Pagination page={page} total={total} href={(p) => eventFilterHref(filter, p)} label="Einsätze" />
        </>
      )}
    </section>
  )
}

function FilterForm({ filter, referate, groups }: { filter: EventFilter; referate: EventListResult['referate']; groups: EventListResult['groups'] }) {
  const navigate = useNavigate()
  const [from, setFrom] = useState(filter.from)
  const [to, setTo] = useState(filter.to)
  const set = (patch: Partial<EventFilter>) => navigate(eventFilterHref({ ...filter, ...patch }), { replace: true })
  const periods = halfYearOptions()
  const hasFilter = filter.referat || filter.group || filter.kind || filter.period !== periods[1].value

  return (
    <form
      role="search"
      onSubmit={(e) => {
        e.preventDefault()
        set({ from, to })
      }}
      className="flex flex-col gap-4 sm:flex-row sm:flex-wrap sm:items-end"
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="ez-period">Zeitraum</Label>
        <select id="ez-period" value={filter.period} onChange={(e) => set({ period: e.target.value })} className={selectClassName}>
          {periods.map((p) => (
            <option key={p.value} value={p.value}>
              {p.label}
            </option>
          ))}
          <option value="frei">frei wählen</option>
        </select>
      </div>
      {filter.period === 'frei' && (
        <>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ez-from">von</Label>
            <Input id="ez-from" type="date" value={from} onChange={(e) => setFrom(e.target.value)} onBlur={() => set({ from, to })} />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ez-to">bis</Label>
            <Input id="ez-to" type="date" value={to} onChange={(e) => setTo(e.target.value)} onBlur={() => set({ from, to })} />
          </div>
        </>
      )}
      <div className="flex flex-col gap-2">
        <Label htmlFor="ez-referat">Referat</Label>
        <select id="ez-referat" value={filter.referat} onChange={(e) => set({ referat: e.target.value })} className={selectClassName}>
          <option value="">alle</option>
          {referate.map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="ez-group">Gruppe</Label>
        <select id="ez-group" value={filter.group} onChange={(e) => set({ group: e.target.value })} className={selectClassName}>
          <option value="">alle</option>
          {groups.map((g) => (
            <option key={g.id} value={g.id}>
              {g.name}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="ez-kind">Einsatzart</Label>
        <select
          id="ez-kind"
          value={filter.kind}
          onChange={(e) => set({ kind: e.target.value as EventKind | '' })}
          className={selectClassName}
        >
          <option value="">alle</option>
          {KINDS.map((k) => (
            <option key={k} value={k}>
              {KIND_LABELS[k]}
            </option>
          ))}
        </select>
      </div>
      {hasFilter && (
        <Button variant="ghost" asChild className="self-start sm:self-auto">
          <Link to="/ez" replace>
            Filter zurücksetzen
          </Link>
        </Button>
      )}
    </form>
  )
}

/** Gruppe bzw. Titel; bei Training die Gruppe, sonst Titel mit Gruppe darunter. */
function EventName({ event }: { event: EventRow }) {
  const name = event.kind === 'training' ? event.group_name : event.title
  return (
    <span className="flex flex-col gap-0.5">
      <Link
        to={`/ez/${event.id}`}
        className={cn('font-medium underline-offset-4 hover:underline', event.is_cancelled && 'text-muted-foreground line-through')}
      >
        {name ?? KIND_LABELS[event.kind]}
      </Link>
      {event.kind !== 'training' && event.group_name && <span className="text-sm text-muted-foreground">{event.group_name}</span>}
      {event.is_cancelled && (
        <Badge variant="outline" className="self-start">
          abgesagt
        </Badge>
      )}
      {event.is_settled && (
        <span className="self-start">
          <SettledBadge />
        </span>
      )}
    </span>
  )
}

function Present({ event }: { event: EventRow }) {
  const summary = presentSummary(event.present_trainer, event.present_helper, event.present_participant)
  const registered = event.registered_count > 0 ? ` · ${event.registered_count} eingetragen` : ''
  return <span className={cn('tabular-nums', event.is_cancelled && 'text-muted-foreground')}>{summary + registered}</span>
}

const COLUMNS: Column<EventRow>[] = [
  { key: 'date', header: 'Datum', cell: (e) => formatEventDate(e.start_date, e.end_date), className: 'tabular-nums' },
  { key: 'kind', header: 'Einsatzart', cell: (e) => KIND_LABELS[e.kind] },
  { key: 'name', header: 'Gruppe oder Titel', cell: (e) => <EventName event={e} />, className: 'whitespace-normal' },
  { key: 'referat', header: 'Referat', cell: (e) => e.referat_name },
  { key: 'present', header: 'Anwesend', cell: (e) => <Present event={e} /> },
  {
    key: 'open',
    header: <span className="sr-only">Aktion</span>,
    headerClassName: 'w-0',
    cell: (e) => (
      <Button variant="outline" asChild>
        <Link to={`/ez/${e.id}`} aria-label={`Einsatz vom ${formatEventDate(e.start_date, e.end_date)} öffnen`}>
          Öffnen
        </Link>
      </Button>
    ),
  },
]

function EventCard({ event }: { event: EventRow }) {
  return (
    <>
      <div className="flex flex-col gap-1">
        <span className="text-sm text-muted-foreground tabular-nums">
          {formatEventDate(event.start_date, event.end_date)} · {KIND_LABELS[event.kind]}
        </span>
        <EventName event={event} />
        <span className="text-sm text-muted-foreground">{event.referat_name}</span>
        <span className="text-sm">
          <Present event={event} />
        </span>
      </div>
      <Button variant="outline" asChild className="h-11 self-start sm:h-8">
        <Link to={`/ez/${event.id}`} aria-label={`Einsatz vom ${formatEventDate(event.start_date, event.end_date)} öffnen`}>
          Öffnen
        </Link>
      </Button>
    </>
  )
}
