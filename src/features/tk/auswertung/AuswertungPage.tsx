import { FileDownIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Table, TableBody, TableCell, TableFooter, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { downloadBlob } from '@/features/fi/export/pdf'
import { LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { useTkAccess } from '@/features/tk/access'
import { reportCsv, reportHref, type ReportFilter, type ReportResult, type ReportRow } from '@/features/tk/auswertung/data'
import { CheckField } from '@/features/tk/detail/fields'
import { formatMoney, PLAN_TYPE_LABELS } from '@/features/tk/labels'
import { formatSpan } from '@/features/tk/liste/data'
import { StatusBadge } from '@/features/tk/shared'
import type { PlanType } from '@/features/tk/types'
import { todayIso } from '@/lib/format'

const MONEY: { key: keyof ReportRow; header: string }[] = [
  { key: 'fee_total', header: 'Vergütung' },
  { key: 'org_total', header: 'Org.-Pauschale' },
  { key: 'leader_costs', header: 'Kosten Leitung' },
  { key: 'fixed_costs', header: 'Sonstige Kosten' },
  { key: 'total_costs', header: 'Gesamtkosten' },
]

const RESULT: { key: keyof ReportRow; header: string }[] = [
  { key: 'result_min', header: 'Ergebnis Min.' },
  { key: 'result_max', header: 'Ergebnis Max.' },
  { key: 'section_bears', header: 'Sektion trägt' },
]

function sum(rows: ReportRow[], key: keyof ReportRow): number {
  return rows.reduce((s, r) => s + (typeof r[key] === 'number' ? (r[key] as number) : 0), 0)
}

// T024 (US-TK-20): Kostenauswertung aller lesbaren Planungen mit Summenzeile; Filter Jahr, Referat, Tourtyp, abgesagte;
// CSV nur für die Geschäftsstelle (A7). Keine Kontakt- oder Notfalldaten.
export function AuswertungPage() {
  const { filter, rows: all, failed } = useLoaderData() as ReportResult
  const { canManage } = useTkAccess()
  const navigate = useNavigate()
  const go = (next: Partial<ReportFilter>) => navigate(reportHref({ ...filter, ...next }))
  const referate = [...new Map(all.map((r) => [r.referat_id, r.referat_name])).entries()]
  const rows = filter.referat ? all.filter((r) => r.referat_id === filter.referat) : all
  const thisYear = Number(todayIso().slice(0, 4))

  function csv() {
    downloadBlob(new Blob([reportCsv(rows)], { type: 'text/csv;charset=utf-8' }), `Kostenauswertung_Touren_Kurse_${filter.year}.csv`)
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-2xl font-semibold tracking-tight">Kostenauswertung</h1>
          <p className="text-sm text-muted-foreground">Geplante Kosten und Beiträge der Planungen eines Jahres.</p>
        </div>
        {canManage && (
          <Button variant="outline" onClick={csv} disabled={rows.length === 0}>
            <FileDownIcon data-icon="inline-start" aria-hidden="true" />
            CSV herunterladen
          </Button>
        )}
      </div>

      <div className="flex flex-wrap items-end gap-4">
        <div className="flex flex-col gap-2">
          <Label htmlFor="tk-r-year">Jahr</Label>
          <select id="tk-r-year" className={selectClassName} value={filter.year} onChange={(e) => go({ year: Number(e.target.value) })}>
            {[thisYear - 2, thisYear - 1, thisYear, thisYear + 1, thisYear + 2].map((y) => (
              <option key={y} value={y}>
                {y}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="tk-r-referat">Referat</Label>
          <select id="tk-r-referat" className={selectClassName} value={filter.referat ?? ''} onChange={(e) => go({ referat: e.target.value || null })}>
            <option value="">alle lesbaren</option>
            {referate.map(([id, name]) => (
              <option key={id} value={id}>
                {name}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="tk-r-type">Tourtyp</Label>
          <select id="tk-r-type" className={selectClassName} value={filter.type ?? ''} onChange={(e) => go({ type: (e.target.value || null) as PlanType | null })}>
            <option value="">alle</option>
            {(Object.keys(PLAN_TYPE_LABELS) as PlanType[]).map((t) => (
              <option key={t} value={t}>
                {PLAN_TYPE_LABELS[t]}
              </option>
            ))}
          </select>
        </div>
        <div className="flex h-8 items-center">
          <CheckField label="abgesagte anzeigen" checked={filter.cancelled} onChange={(v) => go({ cancelled: v })} />
        </div>
      </div>

      {failed ? (
        <LoadFailed />
      ) : (
        <>
          {rows.length === 0 && <p className="text-sm text-muted-foreground">Keine Planungen für diese Auswahl.</p>}
          <div className="overflow-x-auto rounded-xl border">
            <Table>
              <caption className="sr-only">Kostenauswertung {filter.year}</caption>
              <TableHeader>
                <TableRow className="bg-muted hover:bg-muted">
                  <TableHead className="pl-4">Planung</TableHead>
                  <TableHead>Status</TableHead>
                  {MONEY.map((m) => (
                    <TableHead key={m.key} className="text-right">{m.header}</TableHead>
                  ))}
                  <TableHead className="text-right">Beitrag Mitgl.</TableHead>
                  <TableHead className="text-right">Min./Max.</TableHead>
                  {RESULT.map((m) => (
                    <TableHead key={m.key} className="pr-4 text-right last:pr-4">{m.header}</TableHead>
                  ))}
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((r) => (
                  <TableRow key={r.id} className="hover:bg-transparent">
                    <TableCell className="pl-4">
                      <Link to={`/tk/${r.id}`} className="font-medium underline-offset-4 hover:underline">
                        {r.title}
                      </Link>
                      <span className="block text-xs text-muted-foreground">
                        {PLAN_TYPE_LABELS[r.plan_type]} · {formatSpan(r.start_date, r.end_date)}
                      </span>
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={r.status} />
                    </TableCell>
                    {MONEY.map((m) => (
                      <TableCell key={m.key} className="text-right tabular-nums">{formatMoney(r[m.key] as number | null)}</TableCell>
                    ))}
                    <TableCell className="text-right tabular-nums">{formatMoney(r.price_member_effective, true)}</TableCell>
                    <TableCell className="text-right tabular-nums">{r.min_participants ?? '–'}/{r.max_participants ?? '–'}</TableCell>
                    {RESULT.map((m) => (
                      <TableCell key={m.key} className="pr-4 text-right tabular-nums">{formatMoney(r[m.key] as number | null)}</TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
              <TableFooter>
                <TableRow>
                  <TableCell className="pl-4 font-medium" colSpan={2}>
                    Summe ({rows.length} Planungen)
                  </TableCell>
                  {MONEY.map((m) => (
                    <TableCell key={m.key} className="text-right font-medium tabular-nums">{formatMoney(sum(rows, m.key))}</TableCell>
                  ))}
                  <TableCell />
                  <TableCell />
                  {RESULT.map((m) => (
                    <TableCell key={m.key} className="pr-4 text-right font-medium tabular-nums">{formatMoney(sum(rows, m.key))}</TableCell>
                  ))}
                </TableRow>
              </TableFooter>
            </Table>
          </div>
        </>
      )}
    </div>
  )
}
