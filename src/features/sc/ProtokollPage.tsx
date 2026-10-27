import { useLoaderData, useNavigate } from 'react-router-dom'
import { Pagination } from '@/components/Pagination'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Badge } from '@/components/ui/badge'
import { LOG_KIND_LABELS, LOG_RESULT_LABELS, type LogData, type LogFilter, type LogRow } from '@/features/sc/data'
import { FilterDate, FilterSelect, LoadFailed } from '@/features/sc/ui'
import { formatDateTime } from '@/lib/format'

const PARAMS: Record<keyof LogFilter, string> = { connection: 'anbindung', kind: 'art', result: 'ergebnis', from: 'von', to: 'bis' }

function href(filter: LogFilter, page = 1) {
  const p = new URLSearchParams()
  for (const key of Object.keys(PARAMS) as (keyof LogFilter)[]) if (filter[key]) p.set(PARAMS[key], filter[key])
  if (page > 1) p.set('seite', String(page))
  const q = p.toString()
  return q ? `/schnittstellen/protokoll?${q}` : '/schnittstellen/protokoll'
}

// US-SC-11: Aufrufe und Änderungen der letzten 90 Tage, neueste zuerst; ohne Key und ohne Inhalt der E-Mails (R15).
export function ProtokollPage() {
  const data = useLoaderData() as LogData
  const navigate = useNavigate()

  if (data.failed) return <LoadFailed title="Protokoll" />

  const setFilter = (key: keyof LogFilter, value: string) => navigate(href({ ...data.filter, [key]: value }))
  const connectionName = (id: string | null) => (id ? (data.connections.find((c) => c.id === id)?.name ?? '–') : '–')
  const actor = (r: LogRow) => (r.actor_user_id ? (data.actors[r.actor_user_id] ?? 'Nutzer:in') : 'Job')
  const result = (r: LogRow) => (
    <Badge variant={r.result === 'ok' ? 'secondary' : 'destructive'}>{LOG_RESULT_LABELS[r.result]}</Badge>
  )

  const columns: Column<LogRow>[] = [
    { key: 'time', header: 'Zeitpunkt', cell: (r) => formatDateTime(r.created_at), className: 'whitespace-nowrap tabular-nums' },
    { key: 'connection', header: 'Anbindung', cell: (r) => connectionName(r.connection_id) },
    { key: 'module', header: 'Modul', cell: (r) => r.module_code ?? '–' },
    { key: 'actor', header: 'Von', cell: actor },
    { key: 'kind', header: 'Art', cell: (r) => LOG_KIND_LABELS[r.kind] ?? r.kind },
    { key: 'result', header: 'Ergebnis', cell: result },
    { key: 'message', header: 'Meldung', cell: (r) => r.message ?? '–', className: 'whitespace-normal break-words' },
  ]

  return (
    <section className="flex flex-col gap-4">
      <div className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold">Protokoll</h1>
        <p className="text-sm text-muted-foreground">
          Versand, Tests und Änderungen an Anbindungen, Freigaben und Vorlagen der letzten 90 Tage.
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <FilterSelect
          id="sc-log-connection"
          label="Anbindung"
          value={data.filter.connection}
          options={data.connections.map((c) => ({ value: c.id, label: c.name }))}
          onChange={(v) => setFilter('connection', v)}
        />
        <FilterSelect
          id="sc-log-kind"
          label="Art"
          value={data.filter.kind}
          options={Object.entries(LOG_KIND_LABELS).map(([value, label]) => ({ value, label }))}
          onChange={(v) => setFilter('kind', v)}
        />
        <FilterSelect
          id="sc-log-result"
          label="Ergebnis"
          value={data.filter.result}
          options={Object.entries(LOG_RESULT_LABELS).map(([value, label]) => ({ value, label }))}
          onChange={(v) => setFilter('result', v)}
        />
        <FilterDate id="sc-log-from" label="von" value={data.filter.from} onChange={(v) => setFilter('from', v)} />
        <FilterDate id="sc-log-to" label="bis" value={data.filter.to} onChange={(v) => setFilter('to', v)} />
      </div>

      <ResponsiveTable
        rows={data.rows}
        rowKey={(r) => String(r.id)}
        columns={columns}
        empty="Keine Einträge in den letzten 90 Tagen."
        caption="Protokoll der Schnittstellen"
        card={(r) => (
          <div className="flex flex-col gap-1 text-sm">
            <span className="flex items-center justify-between gap-2">
              <span className="font-medium">{LOG_KIND_LABELS[r.kind] ?? r.kind}</span>
              {result(r)}
            </span>
            <span className="text-muted-foreground tabular-nums">
              {formatDateTime(r.created_at)} · {actor(r)}
            </span>
            {r.message && <span className="break-words">{r.message}</span>}
          </div>
        )}
      />
      <Pagination page={data.page} total={data.total} href={(p) => href(data.filter, p)} label="Einträge" />
    </section>
  )
}
