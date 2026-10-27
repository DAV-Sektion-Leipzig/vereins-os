import { useMemo, useState } from 'react'
import { CircleAlertIcon, PlusIcon, RotateCwIcon } from 'lucide-react'
import { Link, useLoaderData, useRevalidator, useSearchParams } from 'react-router-dom'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  KIND_LABELS,
  KINDS,
  LEVEL_LABELS,
  STATUS_LABELS,
  type ListResult,
  type QualificationKind,
  type QualificationStatus,
  type QualificationType,
} from '@/features/ad/qualifikationsarten/data'
import { MESSAGES } from '@/lib/errors'
import { cn } from '@/lib/utils'

const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:w-auto sm:text-sm'

// T077 (US-AD-17 AK1): Liste gruppiert nach Sparte; Suche und Filter im Browser, weil die Liste klein ist.
// `basePath` erlaubt dieselbe Seite unter /ea/qualifikationsarten (spec.md AD Abschnitt 6).
export function QualifikationsartenListe({ basePath = '/ad/qualifikationsarten' }: { basePath?: string }) {
  const { items, canEdit, usage, failed } = useLoaderData() as ListResult
  const revalidator = useRevalidator()
  const [params, setParams] = useSearchParams()
  const [q, setQ] = useState(params.get('q') ?? '')

  const discipline = params.get('sparte') ?? ''
  const kind = (params.get('typ') ?? '') as QualificationKind | ''
  const status = (params.get('status') ?? 'current') as QualificationStatus | 'alle'

  function setParam(key: string, value: string) {
    const next = new URLSearchParams(params)
    if (value) next.set(key, value)
    else next.delete(key)
    setParams(next, { replace: true })
  }

  const disciplines = useMemo(() => [...new Set(items.map((i) => i.discipline))].sort((a, b) => a.localeCompare(b, 'de')), [items])

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return items.filter(
      (i) =>
        (status === 'alle' || i.status === status) &&
        (!discipline || i.discipline === discipline) &&
        (!kind || i.kind === kind) &&
        (!needle || i.name.toLowerCase().includes(needle) || (i.code ?? '').toLowerCase().includes(needle)),
    )
  }, [items, q, discipline, kind, status])

  const groups = useMemo(() => {
    const map = new Map<string, QualificationType[]>()
    for (const i of filtered) map.set(i.discipline, [...(map.get(i.discipline) ?? []), i])
    return [...map.entries()]
  }, [filtered])

  // Feste Breiten, damit die Spalten über alle Sparten (je eine Tabelle) in einer Flucht stehen; nur „Bezeichnung“ ist flexibel.
  const dash = <span className="text-muted-foreground">–</span>
  const columns: Column<QualificationType>[] = [
    { key: 'code', header: 'Kürzel', cell: (i) => i.code ?? dash, className: 'font-medium tabular-nums', headerClassName: 'w-24' },
    {
      key: 'name',
      header: 'Bezeichnung',
      cell: (i) => (
        <Link to={`${basePath}/${i.id}`} className="underline-offset-4 hover:underline">
          {i.name}
        </Link>
      ),
      className: 'whitespace-normal',
    },
    { key: 'kind', header: 'Typ', cell: (i) => KIND_LABELS[i.kind], headerClassName: 'w-40' },
    { key: 'level', header: 'Lizenzstufe', cell: (i) => (i.level ? LEVEL_LABELS[i.level] : dash), headerClassName: 'w-32' },
    {
      key: 'validity',
      header: 'Gültigkeitsdauer',
      cell: (i) => (i.validity_years ? `${i.validity_years} ${i.validity_years === 1 ? 'Jahr' : 'Jahre'}` : dash),
      headerClassName: 'w-40',
    },
    {
      key: 'persons',
      header: 'Personen',
      cell: (i) => (usage?.[i.id] ? usage[i.id] : dash),
      className: 'text-right tabular-nums',
      headerClassName: 'w-28 text-right',
    },
    { key: 'status', header: 'Status', cell: (i) => <StatusBadge status={i.status} />, headerClassName: 'w-28' },
  ]

  return (
    <section className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Qualifikationsarten</h1>
        {canEdit && (
          <Button asChild>
            <Link to={`${basePath}/neu`}>
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              Neu
            </Link>
          </Button>
        )}
      </div>

      <div className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end">
        <div className="flex flex-col gap-2 sm:max-w-xs sm:flex-1">
          <Label htmlFor="qt-search">Suche</Label>
          <Input
            id="qt-search"
            type="search"
            value={q}
            onChange={(event) => {
              setQ(event.target.value)
              setParam('q', event.target.value)
            }}
            placeholder="Bezeichnung oder Kürzel"
            autoComplete="off"
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="qt-discipline">Sparte</Label>
          <select id="qt-discipline" value={discipline} onChange={(e) => setParam('sparte', e.target.value)} className={selectClassName}>
            <option value="">alle</option>
            {disciplines.map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="qt-kind">Typ</Label>
          <select id="qt-kind" value={kind} onChange={(e) => setParam('typ', e.target.value)} className={selectClassName}>
            <option value="">alle</option>
            {KINDS.map((k) => (
              <option key={k} value={k}>
                {KIND_LABELS[k]}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="qt-status">Status</Label>
          <select id="qt-status" value={status} onChange={(e) => setParam('status', e.target.value)} className={selectClassName}>
            <option value="current">aktuell</option>
            <option value="historic">historisch</option>
            <option value="alle">alle</option>
          </select>
        </div>
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
      ) : groups.length === 0 ? (
        <p className="text-sm text-muted-foreground">Keine Qualifikationsarten gefunden.</p>
      ) : (
        groups.map(([name, rows]) => (
          <section key={name} aria-labelledby={`sparte-${name}`} className="flex flex-col gap-2">
            <h2 id={`sparte-${name}`} className="font-medium">
              {name} <span className="font-normal text-muted-foreground tabular-nums">({rows.length})</span>
            </h2>
            <ResponsiveTable
              rows={rows}
              rowKey={(i) => i.id}
              columns={columns}
              empty=""
              caption={`Qualifikationsarten ${name}`}
              card={(i) => (
                <div className="flex flex-col gap-1">
                  <Link to={`${basePath}/${i.id}`} className="font-medium underline-offset-4 hover:underline">
                    {i.code ? `${i.code} – ${i.name}` : i.name}
                  </Link>
                  <span className="text-sm text-muted-foreground">
                    {KIND_LABELS[i.kind]}
                    {i.level && ` · Stufe ${LEVEL_LABELS[i.level]}`}
                    {i.validity_years && ` · ${i.validity_years} Jahre`}
                    {usage?.[i.id] && ` · ${usage[i.id]} ${usage[i.id] === 1 ? 'Person' : 'Personen'}`}
                  </span>
                  <StatusBadge status={i.status} className="self-start" />
                </div>
              )}
            />
          </section>
        ))
      )}
    </section>
  )
}

export function StatusBadge({ status, className }: { status: QualificationStatus; className?: string }) {
  return (
    <Badge
      variant="outline"
      className={cn(status === 'current' ? 'bg-status-active-bg text-status-active' : 'bg-status-none-bg text-status-none', className)}
    >
      {STATUS_LABELS[status]}
    </Badge>
  )
}
