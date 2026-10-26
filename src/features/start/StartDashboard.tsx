import { useEffect, useState } from 'react'
import { ChevronRightIcon } from 'lucide-react'
import { Link } from 'react-router-dom'
import { loadDsAccess } from '@/features/ds/access'
import { currentYear, dashboardHref, loadOverview, loadYears, type Head, type OverviewItem, type TodoEntry, type View } from '@/features/ds/budget/data'
import { DataStand, prevDateOf, Tiles, TodoList, VereinTiles } from '@/features/ds/budget/DashboardPage'
import { dsRpc } from '@/features/ds/errors'

type StartData = { year: number; view: View; title: string; head: Head | null; mine: OverviewItem[]; todo: TodoEntry[] }

async function fetchStart(): Promise<StartData> {
  const access = await loadDsAccess()
  const years = await loadYears()
  const year = years.find((y) => y <= currentYear()) ?? years[0] ?? currentYear()
  const referat = access.myReferate[0]
  const view: View = referat && !access.scopeAll ? { kind: 'referat', referatId: referat.id } : { kind: 'verein' }
  const [overview, todo] = await Promise.all([loadOverview(year), dsRpc<TodoEntry[]>('ds_todo')])
  return {
    year,
    view,
    title: view.kind === 'referat' ? `Mein Referat: ${referat!.name}` : 'Verein',
    head: overview.head,
    mine: view.kind === 'referat' ? overview.items.filter((i) => i.referat_id === view.referatId && i.visibility === 'referat') : [],
    todo: todo.data ?? [],
  }
}

// US-DS-20: Mit DS lesen zeigt die Startseite das Dashboard (Sicht „Mein Referat“ bzw. „Verein“, AK1); die Daten
// kommen aus denselben Lesefunktionen wie /dashboard (AK4).
export function StartDashboard() {
  const [data, setData] = useState<StartData | null>(null)
  const [failed, setFailed] = useState(false)

  useEffect(() => {
    let active = true
    fetchStart().then(
      (d) => active && setData(d),
      () => active && setFailed(true),
    )
    return () => {
      active = false
    }
  }, [])

  if (failed) return null
  return (
    <section aria-labelledby="start-dashboard-heading" className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <h2 id="start-dashboard-heading" className="font-medium">
          Dashboard{data ? ` · ${data.title}` : ''}
        </h2>
        {data && (
          <Link to={dashboardHref(data.year, data.view)} className="inline-flex items-center gap-1 text-sm font-medium text-primary hover:text-primary-hover">
            Ganzes Dashboard
            <ChevronRightIcon aria-hidden="true" className="size-4" />
          </Link>
        )}
      </div>
      {!data ? (
        <p role="status" className="text-sm text-muted-foreground">
          Wird geladen …
        </p>
      ) : (
        <>
          <TodoList entries={data.todo} year={data.year} />
          <DataStand head={data.head} year={data.year} />
          {data.view.kind === 'referat' ? data.mine.length > 0 && <Tiles items={data.mine} prevDate={prevDateOf(data.head)} /> : data.head?.has_plan && <VereinTiles head={data.head} />}
        </>
      )}
    </section>
  )
}
