import { PrinterIcon, TriangleAlertIcon } from 'lucide-react'
import { useLoaderData, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { useDsAccess } from '@/features/ds/access'
import { currentYear, groupItems, type Checks, type VereinData } from '@/features/ds/budget/data'
import { DataStand, GroupList, PrintHeader, prevDateOf, usePrintExpand } from '@/features/ds/budget/DashboardPage'
import { BlockHeading, euro, euroCents, PrintLandscape, Tile } from '@/features/ds/budget/ui'
import { LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime } from '@/lib/format'

const AMPEL_ORDER = { no_plan: 0, over: 1, warn: 2, ok: 3 } as const

// US-DS-08, -18, -19: Sicht Verein mit Kopf, Gesamtbudgets nach Ampel, nicht zugeordneten Buchungen und Prüfung
// (die beiden letzten nur mit Reichweite „alle“ oder Budgetpflege, R14).
export function VereinPage() {
  const { years, year, head, items, unassigned, checks, failed } = useLoaderData() as VereinData
  const { scopeAll } = useDsAccess()
  const navigate = useNavigate()
  const [printing, print] = usePrintExpand()

  // Gesamtbudgets nach Ampel: ■ vor ▲ vor ●, dann wie im Finanzplan
  const groups = groupItems(items)
    .map((g, index) => {
      const ex = g.items.filter((i) => i.kind === 'expense')
      const plan = ex.reduce((s, i) => s + Number(i.plan_current), 0)
      const actual = ex.reduce((s, i) => s + Number(i.actual), 0)
      const ampel = plan <= 0 ? (actual > 0 ? 'no_plan' : 'ok') : actual / plan < 0.8 ? 'ok' : actual / plan <= 1 ? 'warn' : 'over'
      return { g, index, rank: ex.length === 0 ? 4 : AMPEL_ORDER[ampel] }
    })
    .sort((a, b) => a.rank - b.rank || a.index - b.index)
    .map((x) => x.g)

  return (
    <div className="flex flex-col gap-8">
      <PrintLandscape />
      <PrintHeader title={`Budget des Vereins · ${year}`} head={head} />
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between print:hidden">
        <h1 className="text-xl font-semibold">Budget des Vereins</h1>
        <div className="flex flex-wrap items-end gap-3">
          {years.length > 1 && (
            <div className="flex flex-col gap-1">
              <Label htmlFor="verein-year">Jahr</Label>
              <select
                id="verein-year"
                className={selectClassName}
                value={year}
                onChange={(e) => navigate(Number(e.target.value) === currentYear() ? '/dashboard/verein' : `/dashboard/verein?jahr=${e.target.value}`)}
              >
                {years.map((y) => (
                  <option key={y} value={y}>
                    {y}
                  </option>
                ))}
              </select>
            </div>
          )}
          <Button variant="outline" onClick={print}>
            <PrinterIcon data-icon="inline-start" aria-hidden="true" />
            Drucken
          </Button>
        </div>
      </div>
      {failed && <LoadFailed />}
      <DataStand head={head} year={year} />

      {head?.has_plan && (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <Tile label="Ausgaben Plan" value={euro(head.expense_plan)} />
          <Tile label="verbraucht" value={euro(head.expense_actual)} />
          <Tile label="frei" value={euro(head.expense_free)} />
          <Tile label="Einnahmen erreicht" value={euro(head.income_actual)}>
            Plan {euro(head.income_plan)} · fehlt noch {euro(head.income_missing)}
          </Tile>
        </div>
      )}

      {groups.length > 0 && (
        <section aria-labelledby="groups-heading" className="flex flex-col gap-3">
          <BlockHeading id="groups-heading" sub="Sortiert nach Ampel: ■ über Plan oder ohne Budget, ▲ knapp, ● im Plan.">
            Gesamtbudgets
          </BlockHeading>
          <GroupList groups={groups} progress={head?.progress ?? null} prevDate={prevDateOf(head)} highlight={null} expandAll={printing} />
        </section>
      )}

      {scopeAll && unassigned && (
        <section aria-labelledby="unassigned-heading" className="flex flex-col gap-3">
          <BlockHeading id="unassigned-heading" sub="Erfolgskonten mit Regel, aber ohne Budgetposten. Betrag Soll − Haben.">
            Nicht zugeordnete Buchungen
          </BlockHeading>
          {unassigned.length === 0 ? (
            <p className="text-sm text-muted-foreground">Alle Buchungen sind einem Budgetposten zugeordnet.</p>
          ) : (
            <div className="overflow-x-auto rounded-xl border">
              <Table className="min-w-[40rem]">
                <TableHeader>
                  <TableRow className="bg-muted hover:bg-muted">
                    <TableHead className="pl-4">Datum</TableHead>
                    <TableHead>Konto</TableHead>
                    <TableHead>Buchungstext</TableHead>
                    <TableHead>Beleg</TableHead>
                    <TableHead className="pr-4 text-right">Betrag</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {unassigned.map((u) => (
                    <TableRow key={u.booking_id}>
                      <TableCell className="pl-4 tabular-nums">{formatDate(u.booking_date)}</TableCell>
                      <TableCell className="tabular-nums">{u.account}</TableCell>
                      <TableCell className="max-w-80 whitespace-normal">{u.booking_text ?? '–'}</TableCell>
                      <TableCell>{u.receipt ?? '–'}</TableCell>
                      <TableCell className="pr-4 text-right tabular-nums">{euroCents(u.amount)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </section>
      )}

      {scopeAll && checks && <CheckSection checks={checks} />}
    </div>
  )
}

const WARNINGS: Record<string, string> = {
  incomplete: 'Export unvollständig',
  rekey_missing: 'Umgeschlüsselte Buchung nicht mehr im Export',
}

export function CheckSection({ checks }: { checks: Checks }) {
  const im = checks.import
  return (
    <section aria-labelledby="check-heading" className="flex flex-col gap-3">
      <BlockHeading id="check-heading">Prüfung</BlockHeading>
      {!im ? (
        <p className="text-sm text-muted-foreground">Noch kein DATEV-Export eingespielt.</p>
      ) : (
        <>
          <p className="text-sm">
            Export „{im.file_name}“ vom {formatDateTime(im.imported_at)}: {im.rows_read} Zeilen gelesen, {im.rows_saved} ausgewertet,{' '}
            {im.rows_ignored} ohne Zuordnung (andere Konten), {im.rows_opening} Saldovorträge, {im.rows_other_year} aus anderen Jahren.
          </p>
          {im.warnings.length > 0 ? (
            <ul className="flex flex-col gap-1.5">
              {im.warnings.map((w, i) => (
                <li key={i} className="flex items-start gap-2 text-sm text-status-locked">
                  <TriangleAlertIcon aria-hidden="true" className="mt-0.5 size-4 shrink-0" />
                  <span>
                    {WARNINGS[w.type] ?? w.type}
                    {w.type === 'incomplete' && `: Konto ${w.konto} – Kontenübersicht ${euroCents(w.overview)}, Einzelbuchungen ${euroCents(w.rows)}`}
                    {w.type === 'rekey_missing' && `: ${w.konto} · ${w.date ? formatDate(w.date) : '–'} · ${euroCents(w.amount)} ${w.side ?? ''}`}
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-status-active">Summe je Konto stimmt mit der Kontenübersicht überein.</p>
          )}
        </>
      )}
      {checks.uncertain.length > 0 && (
        <div className="flex flex-col gap-1">
          <p className="text-sm font-medium">Unsichere oder offene Zuordnungen</p>
          <ul className="text-sm">
            {checks.uncertain.map((u) => (
              <li key={u.rule_id}>
                {u.account} → {u.item ?? 'ohne Budgetposten'} ({u.status === 'open' ? 'offen' : 'unsicher'}){u.note ? `: ${u.note}` : ''}
              </li>
            ))}
          </ul>
        </div>
      )}
      {checks.rekeyed.length > 0 && (
        <div className="flex flex-col gap-1">
          <p className="text-sm font-medium">Umgeschlüsselte Buchungen</p>
          <ul className="text-sm">
            {checks.rekeyed.map((r) => (
              <li key={r.rule_id} className={r.found ? '' : 'text-status-locked'}>
                {r.date ? formatDate(r.date) : '–'} · {r.account} · {euroCents(r.amount)} {r.side ?? ''} → {r.item ?? '–'}
                {r.reason ? ` (${r.reason})` : ''}
                {!r.found && ' · nicht im aktuellen Export'}
              </li>
            ))}
          </ul>
        </div>
      )}
    </section>
  )
}
