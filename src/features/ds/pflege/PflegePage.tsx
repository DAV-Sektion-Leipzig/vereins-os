import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { Label } from '@/components/ui/label'
import { AntraegeTab } from '@/features/ds/pflege/AntraegeTab'
import { pflegeHref, TABS, type LogRow, type PflegeData } from '@/features/ds/pflege/data'
import { FinanzplanTab } from '@/features/ds/pflege/FinanzplanTab'
import { GesamtbudgetsTab } from '@/features/ds/pflege/GesamtbudgetsTab'
import { ImportTab } from '@/features/ds/pflege/ImportTab'
import { LOG_ACTIONS } from '@/features/ds/pflege/shared'
import { ZuordnungTab } from '@/features/ds/pflege/ZuordnungTab'
import { LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { formatDateTime } from '@/lib/format'
import { cn } from '@/lib/utils'

// US-FI-22 bis -27, -29, US-DS-13, -15: Budgetpflege mit Reitern; nur mit dem Kennzeichen „darf Budget pflegen“.
export function PflegePage() {
  const data = useLoaderData() as PflegeData
  const navigate = useNavigate()
  const openCount = data.requests.filter((r) => r.can_decide).length

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <h1 className="text-xl font-semibold">Budgetpflege</h1>
        <div className="flex flex-col gap-1">
          <Label htmlFor="pflege-year">Budgetjahr</Label>
          <select id="pflege-year" className={selectClassName} value={data.year} onChange={(e) => navigate(pflegeHref(data.tab, Number(e.target.value)))}>
            {data.years.map((y) => (
              <option key={y} value={y}>
                {y}
              </option>
            ))}
          </select>
        </div>
      </div>
      {data.failed && <LoadFailed />}
      <nav aria-label="Reiter der Budgetpflege" className="-mx-1 overflow-x-auto">
        <ul className="flex gap-1 px-1">
          {TABS.map((t) => (
            <li key={t.key}>
              <Link
                to={pflegeHref(t.key, data.year)}
                aria-current={data.tab === t.key ? 'page' : undefined}
                className={cn(
                  'inline-flex h-8 items-center rounded-lg border px-3 text-sm whitespace-nowrap outline-none focus-visible:ring-3 focus-visible:ring-ring/50',
                  data.tab === t.key ? 'border-primary bg-accent font-medium text-accent-foreground' : 'hover:bg-muted',
                )}
              >
                {t.label}
                {t.key === 'antraege' && openCount > 0 && <span className="ml-1.5 rounded-full bg-primary px-1.5 text-xs text-primary-foreground">{openCount}</span>}
              </Link>
            </li>
          ))}
        </ul>
      </nav>
      {/* key: Zustand der Reiter beim Jahreswechsel zurücksetzen */}
      <div key={`${data.tab}-${data.year}`}>
        {data.tab === 'finanzplan' && <FinanzplanTab data={data} />}
        {data.tab === 'gesamtbudgets' && <GesamtbudgetsTab data={data} />}
        {data.tab === 'zuordnung' && <ZuordnungTab data={data} />}
        {data.tab === 'import' && <ImportTab data={data} />}
        {data.tab === 'antraege' && <AntraegeTab data={data} />}
        {data.tab === 'protokoll' && <Protokoll log={data.log} />}
      </div>
    </div>
  )
}

function detailText(row: LogRow): string {
  const d = row.details ?? {}
  const parts: string[] = []
  for (const key of ['file', 'account', 'group', 'scope', 'rows_saved', 'items', 'removed', 'rules', 'amount', 'booked']) {
    if (d[key] !== undefined && d[key] !== null && d[key] !== '') parts.push(`${key === 'rows_saved' ? 'Buchungen' : key === 'items' ? 'Posten' : key === 'rules' ? 'Regeln' : key === 'amount' ? 'Betrag' : key === 'removed' ? 'entfallen' : key === 'booked' ? 'gebucht' : key === 'scope' ? 'Umfang' : key === 'group' ? 'Gesamtbudget' : key === 'account' ? 'Konto' : 'Datei'}: ${String(d[key])}`)
  }
  return parts.join(' · ')
}

function Protokoll({ log }: { log: LogRow[] }) {
  if (log.length === 0) return <p className="text-sm text-muted-foreground">Noch keine Einträge.</p>
  return (
    <ul className="flex flex-col divide-y rounded-xl border text-sm">
      {log.map((l) => (
        <li key={l.id} className="flex flex-col gap-0.5 px-3 py-2 sm:flex-row sm:gap-3">
          <span className="shrink-0 text-muted-foreground tabular-nums sm:w-36">{formatDateTime(l.at)}</span>
          <span className="font-medium sm:w-64">
            {LOG_ACTIONS[l.action] ?? l.action}
            {l.year ? ` (${l.year})` : ''}
          </span>
          <span className="min-w-0 text-muted-foreground">{detailText(l)}</span>
        </li>
      ))}
    </ul>
  )
}
