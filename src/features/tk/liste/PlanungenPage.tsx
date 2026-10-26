import { useState } from 'react'
import { CopyIcon, PlusIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Pagination } from '@/components/Pagination'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button, buttonVariants } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { useTkAccess } from '@/features/tk/access'
import { formatMoney, PLAN_TYPE_LABELS, STATUS_LABELS, STATUSES } from '@/features/tk/labels'
import { formatSpan, listHref, type ListFilter, type ListResult, type PlanRow } from '@/features/tk/liste/data'
import { tkRpc } from '@/features/tk/rpc'
import { StatusBadge } from '@/features/tk/shared'
import type { PlanStatus, PlanType } from '@/features/tk/types'
import { todayIso } from '@/lib/format'

// T018 (US-TK-01, -02, -23): Planungen mit Filtern Status (Standard ohne abgesagt/abgeschlossen), Tourtyp, Jahr;
// 50 je Seite, mobil als Karten; „Neue Planung“ und „Kopieren“ mit Schreibrecht.
export function PlanungenPage() {
  const { filter, rows, total, failed } = useLoaderData() as ListResult
  const { canEdit } = useTkAccess()
  const navigate = useNavigate()
  const [copying, setCopying] = useState<string | null>(null)
  const thisYear = Number(todayIso().slice(0, 4))

  function go(next: Partial<ListFilter>) {
    navigate(listHref({ ...filter, ...next }))
  }

  async function copy(row: PlanRow) {
    setCopying(row.id)
    const res = await tkRpc<{ id: string; removed: string[] }>('tk_copy_plan', {
      p_id: row.id,
      p_client_request_id: crypto.randomUUID(),
    })
    setCopying(null)
    if (res.error) return toast.error(res.error.text)
    for (const name of res.data.removed ?? []) toast.info(`${name} ist nicht mehr aktiv und wurde entfernt.`)
    toast.success('Kopie angelegt.')
    navigate(`/tk/${res.data.id}`)
  }

  const statusValue = filter.status ? (filter.status.length === 1 ? filter.status[0] : 'alle') : ''

  const columns: Column<PlanRow>[] = [
    {
      key: 'title',
      header: 'Titel',
      cell: (r) => (
        <Link to={`/tk/${r.id}`} className="font-medium underline-offset-4 hover:underline">
          {r.title}
        </Link>
      ),
    },
    { key: 'type', header: 'Tourtyp', cell: (r) => PLAN_TYPE_LABELS[r.plan_type] },
    { key: 'date', header: 'Termin', cell: (r) => <span className="tabular-nums">{formatSpan(r.start_date, r.end_date)}</span> },
    { key: 'lead', header: 'Leitung', cell: (r) => r.lead_name ?? '–' },
    { key: 'status', header: 'Status', cell: (r) => <StatusBadge status={r.status} /> },
    {
      key: 'price',
      header: 'Beitrag Mitglieder',
      headerClassName: 'text-right',
      className: 'text-right tabular-nums',
      cell: (r) => formatMoney(r.price_member_effective, true),
    },
    ...(canEdit
      ? [
          {
            key: 'actions',
            header: <span className="sr-only">Aktionen</span>,
            className: 'text-right',
            cell: (r: PlanRow) => (
              <Button variant="ghost" size="sm" onClick={() => copy(r)} disabled={copying !== null}>
                <CopyIcon data-icon="inline-start" aria-hidden="true" />
                {copying === r.id ? 'Wird kopiert …' : 'Kopieren'}
              </Button>
            ),
          },
        ]
      : []),
  ]

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-2xl font-semibold tracking-tight">Planungen</h1>
          <p className="text-sm text-muted-foreground">Touren und Kurse von der Planung bis zur Durchführung.</p>
        </div>
        {canEdit && (
          <Link to="/tk/neu" className={buttonVariants()}>
            <PlusIcon data-icon="inline-start" aria-hidden="true" />
            Neue Planung
          </Link>
        )}
      </div>

      <div className="flex flex-wrap gap-4">
        <div className="flex flex-col gap-2">
          <Label htmlFor="tk-filter-status">Status</Label>
          <select
            id="tk-filter-status"
            className={selectClassName}
            value={statusValue}
            onChange={(e) =>
              go({
                status: e.target.value === '' ? null : e.target.value === 'alle' ? STATUSES : [e.target.value as PlanStatus],
                page: 1,
              })
            }
          >
            <option value="">offen (ohne abgesagt, abgeschlossen)</option>
            <option value="alle">alle</option>
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {STATUS_LABELS[s]}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="tk-filter-type">Tourtyp</Label>
          <select
            id="tk-filter-type"
            className={selectClassName}
            value={filter.type ?? ''}
            onChange={(e) => go({ type: (e.target.value || null) as PlanType | null, page: 1 })}
          >
            <option value="">alle</option>
            {(Object.keys(PLAN_TYPE_LABELS) as PlanType[]).map((t) => (
              <option key={t} value={t}>
                {PLAN_TYPE_LABELS[t]}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="tk-filter-year">Jahr</Label>
          <select
            id="tk-filter-year"
            className={selectClassName}
            value={filter.year ?? ''}
            onChange={(e) => go({ year: e.target.value ? Number(e.target.value) : null, page: 1 })}
          >
            <option value="">alle</option>
            {[thisYear - 1, thisYear, thisYear + 1, thisYear + 2].map((y) => (
              <option key={y} value={y}>
                {y}
              </option>
            ))}
          </select>
        </div>
      </div>

      {failed ? (
        <LoadFailed />
      ) : (
        <>
          <ResponsiveTable
            rows={rows}
            rowKey={(r) => r.id}
            columns={columns}
            caption="Planungen"
            empty="Noch keine Planungen."
            card={(r) => (
              <>
                <div className="flex items-start justify-between gap-3">
                  <Link to={`/tk/${r.id}`} className="font-medium underline-offset-4 hover:underline">
                    {r.title}
                  </Link>
                  <StatusBadge status={r.status} />
                </div>
                <p className="text-sm text-muted-foreground">
                  {PLAN_TYPE_LABELS[r.plan_type]} · <span className="tabular-nums">{formatSpan(r.start_date, r.end_date)}</span>
                  {r.lead_name ? ` · ${r.lead_name}` : ''}
                </p>
                <div className="flex items-center justify-between gap-3 text-sm">
                  <span className="tabular-nums">{formatMoney(r.price_member_effective, true)}</span>
                  {canEdit && (
                    <Button variant="outline" size="sm" className="h-11 sm:h-7" onClick={() => copy(r)} disabled={copying !== null}>
                      <CopyIcon data-icon="inline-start" aria-hidden="true" />
                      Kopieren
                    </Button>
                  )}
                </div>
              </>
            )}
          />
          <Pagination page={filter.page} total={total} href={(p) => listHref(filter, p)} label="Planungen" />
        </>
      )}
    </div>
  )
}
