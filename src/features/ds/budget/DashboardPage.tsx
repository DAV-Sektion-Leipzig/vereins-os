import { useEffect, useState } from 'react'
import { ArrowLeftRightIcon, ChevronDownIcon, PrinterIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { useDsAccess } from '@/features/ds/access'
import {
  dashboardHref,
  expenseTotals,
  groupItems,
  type DashboardData,
  type Group,
  type Head,
  type OverviewItem,
  type TodoEntry,
  type View,
} from '@/features/ds/budget/data'
import { NoteDialog, ReallocDialog } from '@/features/ds/budget/dialogs'
import { ItemTable } from '@/features/ds/budget/ItemTable'
import { AmpelBadge, BlockHeading, BudgetBar, euro, pct, PrevYear, PrintLandscape, Tile } from '@/features/ds/budget/ui'
import { DS_MESSAGES } from '@/features/ds/errors'
import { LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime } from '@/lib/format'
import { cn } from '@/lib/utils'

/** Alle Gesamtbudgets aufklappen, solange gedruckt wird (US-DS-19 AK1). */
export function usePrintExpand(): [boolean, () => void] {
  const [printing, setPrinting] = useState(false)
  useEffect(() => {
    const before = () => setPrinting(true)
    const after = () => setPrinting(false)
    window.addEventListener('beforeprint', before)
    window.addEventListener('afterprint', after)
    return () => {
      window.removeEventListener('beforeprint', before)
      window.removeEventListener('afterprint', after)
    }
  }, [])
  return [
    printing,
    () => {
      setPrinting(true)
      window.setTimeout(() => window.print(), 50)
    },
  ]
}

/** „Datenstand 30.09.2026 (letzte Buchung) · Strich = Jahresfortschritt 75 %“ */
export function DataStand({ head, year }: { head: Head | null; year: number }) {
  if (!head?.has_plan) return <p className="text-sm text-muted-foreground">{DS_MESSAGES.noPlan(year)}</p>
  if (!head.data_until) return <p className="text-sm text-muted-foreground">{DS_MESSAGES.noImport(year)}</p>
  return (
    <p className="text-sm text-muted-foreground">
      Datenstand {formatDate(head.data_until)} (letzte Buchung) · Strich = Jahresfortschritt {pct(head.progress)}
      {head.data_stale && ' · Datenstand älter als 6 Wochen'}
    </p>
  )
}

export function PrintHeader({ title, head }: { title: string; head: Head | null }) {
  const [printedAt] = useState(() => new Date())
  return (
    <div className="hidden print:block">
      <p className="text-lg font-semibold">{title}</p>
      <p className="text-sm">
        {head?.data_until ? `Datenstand ${formatDate(head.data_until)} · ` : ''}gedruckt {formatDateTime(printedAt)}
      </p>
    </div>
  )
}

/** Datum des Vorjahres zum gleichen Stichtag („30.09.2025“). */
export function prevDateOf(head: Head | null): string | undefined {
  if (!head?.data_until) return undefined
  const [y, m, d] = head.data_until.split('-').map(Number)
  return `${String(d).padStart(2, '0')}.${String(m).padStart(2, '0')}.${y - 1}`
}

// US-DS-07, -08, -10, -11, -12, -16, -17, -19: Sichtwahl, Jahr, Block ① Zu tun, ② Budget meines Referats,
// ④ Budget des Vereins (zugeklappt, eigenes Referat hervorgehoben).
export function DashboardPage() {
  const data = useLoaderData() as DashboardData
  const { years, year, view, head, items, todo, failed } = data
  const access = useDsAccess()
  const navigate = useNavigate()
  const [printing, print] = usePrintExpand()
  const [noteFor, setNoteFor] = useState<OverviewItem | null>(null)
  const [realloc, setRealloc] = useState(false)

  const viewReferate = access.scopeAll
    ? access.referate.filter((r) => items.some((i) => i.referat_id === r.id) || access.myReferate.some((m) => m.id === r.id))
    : access.myReferate
  const referat = view.kind === 'referat' ? access.referate.find((r) => r.id === view.referatId) : undefined
  const mine = view.kind === 'referat' ? items.filter((i) => i.referat_id === view.referatId && i.visibility === 'referat') : []
  const canRealloc = mine.some((i) => i.can_edit && i.kind === 'expense')
  const prevDate = prevDateOf(head)

  function go(nextYear: number, nextView: View) {
    navigate(dashboardHref(nextYear, nextView))
  }

  return (
    <div className="flex flex-col gap-8">
      <PrintLandscape />
      <PrintHeader title={`Dashboard · ${referat ? `Referat ${referat.name}` : 'Verein'} · ${year}`} head={head} />
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between print:hidden">
        <h1 className="text-xl font-semibold">Dashboard</h1>
        <div className="flex flex-wrap items-end gap-3">
          <div className="flex flex-col gap-1">
            <Label htmlFor="ds-view">Sicht</Label>
            <select
              id="ds-view"
              className={selectClassName + ' sm:max-w-80'}
              value={view.kind === 'verein' ? 'verein' : view.referatId}
              onChange={(e) => go(year, e.target.value === 'verein' ? { kind: 'verein' } : { kind: 'referat', referatId: e.target.value })}
            >
              {viewReferate.map((r) => (
                <option key={r.id} value={r.id}>
                  {access.myReferate.some((m) => m.id === r.id) ? `Mein Referat: ${r.name}` : `Referat ${r.name}`}
                </option>
              ))}
              <option value="verein">Verein</option>
            </select>
          </div>
          {years.length > 1 && (
            <div className="flex flex-col gap-1">
              <Label htmlFor="ds-year">Jahr</Label>
              <select id="ds-year" className={selectClassName} value={year} onChange={(e) => go(Number(e.target.value), view)}>
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

      <section aria-labelledby="todo-heading" className="flex flex-col gap-3 print:hidden">
        <BlockHeading id="todo-heading">① Zu tun</BlockHeading>
        <TodoList entries={todo} year={year} />
      </section>

      {view.kind === 'referat' ? (
        <section aria-labelledby="mine-heading" className="flex flex-col gap-4">
          <BlockHeading id="mine-heading" sub={<DataStand head={head} year={year} />}>
            ② Budget {access.myReferate.some((m) => m.id === view.referatId) ? 'meines Referats' : 'des Referats'} · {referat?.name ?? '–'}
          </BlockHeading>
          {head?.has_plan && mine.length === 0 && <p className="text-sm text-muted-foreground">{DS_MESSAGES.noReferatBudget}</p>}
          {mine.length > 0 && (
            <>
              <Tiles items={mine} prevDate={prevDate} />
              <ItemTable items={mine} progress={head?.progress ?? null} prevDate={prevDate} showGroup={new Set(mine.map((i) => i.group_id)).size > 1} onNote={setNoteFor} />
              {canRealloc && (
                <div className="print:hidden">
                  <Button variant="outline" onClick={() => setRealloc(true)}>
                    <ArrowLeftRightIcon data-icon="inline-start" aria-hidden="true" />
                    Umschichtung beantragen
                  </Button>
                </div>
              )}
            </>
          )}
        </section>
      ) : (
        <section aria-labelledby="head-heading" className="flex flex-col gap-4">
          <BlockHeading id="head-heading" sub={<DataStand head={head} year={year} />}>
            ② Budget des Vereins · {year}
          </BlockHeading>
          {head?.has_plan && <VereinTiles head={head} />}
        </section>
      )}

      {items.length > 0 && (
        <section aria-labelledby="verein-heading" className="flex flex-col gap-3">
          <BlockHeading id="verein-heading" sub="Summen aller Gesamtbudgets. Einzelbuchungen siehst du nur für dein Referat.">
            ④ Budget des Vereins
          </BlockHeading>
          <GroupList
            groups={expenseFirst(groupItems(items))}
            progress={head?.progress ?? null}
            prevDate={prevDate}
            highlight={view.kind === 'referat' ? view.referatId : null}
            expandAll={printing}
            onNote={setNoteFor}
          />
        </section>
      )}

      {noteFor && <NoteDialog item={noteFor} onClose={() => setNoteFor(null)} />}
      {realloc && <ReallocDialog items={mine} onClose={() => setRealloc(false)} />}
    </div>
  )
}

/** Gesamtbudgets mit Ausgaben zuerst, reine Einnahmen danach (Reihenfolge sonst wie im Finanzplan). */
function expenseFirst(groups: Group[]): Group[] {
  const income = (g: Group) => g.items.every((i) => i.kind === 'income')
  return [...groups.filter((g) => !income(g)), ...groups.filter(income)]
}

export function Tiles({ items, prevDate }: { items: OverviewItem[]; prevDate?: string }) {
  const t = expenseTotals(items)
  return (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <Tile label="Plan (aktuell)" value={euro(t.plan)}>
        beschlossen {euro(t.planDecided)}
      </Tile>
      <Tile label="verbraucht" value={euro(t.actual)}>
        <PrevYear value={t.prevSameDay} current={t.actual} found={t.prevSameDay !== null} date={prevDate} />
      </Tile>
      <Tile label="frei" value={euro(t.free)}>
        {t.preview > 0 ? `Vorschau: ${euro(t.preview)} abgerechnet, noch nicht gebucht` : 'ohne Vorschau'}
      </Tile>
      <Tile label="Verbrauch" value={pct(t.pct)}>
        <AmpelBadge ampel={t.ampel} />
      </Tile>
    </div>
  )
}

export function VereinTiles({ head }: { head: Head }) {
  const p = head.expense_plan > 0 ? (head.expense_actual / head.expense_plan) * 100 : null
  return (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <Tile label="Ausgaben Plan" value={euro(head.expense_plan)} />
      <Tile label="verbraucht" value={euro(head.expense_actual)}>
        {pct(p)} des Plans
      </Tile>
      <Tile label="frei" value={euro(head.expense_free)} />
      <Tile label="Einnahmen erreicht" value={euro(head.income_actual)}>
        Plan {euro(head.income_plan)} · fehlt noch {euro(head.income_missing)}
      </Tile>
    </div>
  )
}

type GroupListProps = {
  groups: Group[]
  progress: number | null
  prevDate?: string
  highlight: string | null
  expandAll: boolean
  onNote?: (item: OverviewItem) => void
}

/** Gesamtbudgets zugeklappt; Klick klappt die Budgetposten auf. */
export function GroupList({ groups, progress, prevDate, highlight, expandAll, onNote }: GroupListProps) {
  const [open, setOpen] = useState<Set<string>>(new Set())
  return (
    <ul className="flex flex-col gap-2">
      {groups.map((g) => {
        const t = expenseTotals(g.items)
        const isOpen = expandAll || open.has(g.id)
        const own = highlight !== null && g.referat_id === highlight
        const incomeOnly = g.items.every((i) => i.kind === 'income')
        const income = g.items.filter((i) => i.kind === 'income').reduce((s, i) => s + Number(i.actual), 0)
        return (
          <li key={g.id} className={cn('rounded-xl border bg-card', own && 'border-primary ring-1 ring-primary/30')}>
            <button
              type="button"
              aria-expanded={isOpen}
              onClick={() =>
                setOpen((s) => {
                  const next = new Set(s)
                  if (next.has(g.id)) next.delete(g.id)
                  else next.add(g.id)
                  return next
                })
              }
              className="grid w-full grid-cols-[1fr_auto] items-center gap-x-3 gap-y-1.5 rounded-xl px-3 py-2.5 text-left outline-none hover:bg-muted/50 focus-visible:ring-3 focus-visible:ring-ring/50 sm:grid-cols-[minmax(10rem,1.6fr)_7rem_7rem_minmax(8rem,1.4fr)_7.5rem_1.5rem]"
            >
              <span className="flex min-w-0 flex-col">
                <span className="truncate font-medium">{g.name}</span>
                <span className="text-xs text-muted-foreground">
                  {g.visibility === 'referat' ? `Referat ${g.referat_name}` : g.visibility === 'all' ? 'alle' : 'ohne Referat'}
                  {own && ' · dein Referat'}
                </span>
              </span>
              <ChevronDownIcon aria-hidden="true" className={cn('size-4 shrink-0 justify-self-end transition-transform sm:order-last', isOpen && 'rotate-180', 'print:hidden')} />
              {incomeOnly ? (
                <span className="col-span-2 text-sm tabular-nums sm:col-span-4">Einnahmen erreicht {euro(income)}</span>
              ) : (
                <>
                  <span className="text-sm tabular-nums sm:text-right">
                    <span className="text-muted-foreground sm:hidden">Plan </span>
                    {euro(t.plan)}
                  </span>
                  <span className="text-sm tabular-nums sm:text-right">
                    <span className="text-muted-foreground sm:hidden">verbraucht </span>
                    {euro(t.actual)}
                  </span>
                  <span className="col-span-2 sm:col-span-1">
                    <BudgetBar plan={t.plan} actual={t.actual} preview={t.preview} progress={progress} ampel={t.ampel} label={`${g.name}: ${euro(t.actual)} von ${euro(t.plan)}`} />
                  </span>
                  <span>
                    <AmpelBadge ampel={t.ampel} />
                  </span>
                </>
              )}
            </button>
            {isOpen && (
              <div className="border-t p-3">
                <ItemTable items={g.items} progress={progress} prevDate={prevDate} onNote={onNote} />
              </div>
            )}
          </li>
        )
      })}
    </ul>
  )
}

// ---------------------------------------------------------------------------------------------------------------

const REQUEST_STATUS: Record<string, string> = {
  requested: 'beantragt',
  proposed: 'vorgeschlagen',
  confirmed: 'bestätigt',
  accepted: 'angenommen',
  rejected: 'abgelehnt',
  withdrawn: 'zurückgezogen',
  obsolete: 'gegenstandslos',
}

function todoText(t: TodoEntry): { tag: string; text: string; link?: { to: string; label: string } } | null {
  switch (t.type) {
    case 'settlements_confirm':
      return {
        tag: 'Finanzen',
        text: `${t.count} Abrechnung${t.count === 1 ? '' : 'en'} zur Bestätigung${t.deadline ? ` · Frist ${formatDate(t.deadline)}` : ''}`,
        link: { to: '/fi?bestaetigen=1', label: 'Abrechnungen' },
      }
    case 'own_reallocation':
      return {
        tag: 'Umschichtung',
        text: `${t.from_name} → ${t.to_name}, ${euro(t.amount)}: ${REQUEST_STATUS[t.status ?? ''] ?? t.status}${t.decision_reason ? ` (${t.decision_reason})` : ''}`,
      }
    case 'own_proposal':
      return {
        tag: 'Vorschlag',
        text: `Umschlüsselung ${t.from_name ?? ''} → ${t.to_name}, ${euro(t.amount)}: ${REQUEST_STATUS[t.status ?? ''] ?? t.status}${t.decision_reason ? ` (${t.decision_reason})` : ''}`,
      }
    case 'reallocations_open':
      return { tag: 'Budgetpflege', text: `${t.count} Umschichtung${t.count === 1 ? '' : 'en'} zu bestätigen`, link: { to: '/dashboard/budget/pflege?reiter=antraege', label: 'Anträge' } }
    case 'proposals_open':
      return { tag: 'Budgetpflege', text: `${t.count} Umschlüsselungs-Vorschl${t.count === 1 ? 'ag' : 'äge'} zu entscheiden`, link: { to: '/dashboard/budget/pflege?reiter=antraege', label: 'Anträge' } }
    case 'unassigned':
      return { tag: 'Budgetpflege', text: `${t.count} nicht zugeordnete Buchung${t.count === 1 ? '' : 'en'}`, link: { to: '/dashboard/verein', label: 'Verein' } }
    case 'rules_uncertain':
      return { tag: 'Budgetpflege', text: `${t.count} unsichere oder offene Zuordnung${t.count === 1 ? '' : 'en'}`, link: { to: '/dashboard/budget/pflege?reiter=zuordnung', label: 'Zuordnung' } }
    case 'data_stale':
      return {
        tag: 'Budgetpflege',
        text: `Neuen DATEV-Export einspielen${t.data_until ? ` (Datenstand ${formatDate(t.data_until)})` : ''}`,
        link: { to: '/dashboard/budget/pflege?reiter=import', label: 'Import' },
      }
    case 'purge_failed':
      return { tag: 'Budgetpflege', text: 'Der Löschlauf der Einzelbuchungen ist fehlgeschlagen. Bitte den Admin informieren.' }
    default:
      return null
  }
}

export function TodoList({ entries, year }: { entries: TodoEntry[]; year: number }) {
  const rows = entries.map(todoText).filter((t) => t !== null)
  if (rows.length === 0) return <p className="text-sm text-muted-foreground">Gerade steht nichts an.</p>
  return (
    <ul className="flex flex-col divide-y rounded-xl border" data-year={year}>
      {rows.map((t, i) => (
        <li key={i} className="flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-2.5 text-sm">
          <span className="inline-flex h-5 items-center rounded-full bg-status-invited-bg px-2 text-xs font-medium text-status-invited">{t.tag}</span>
          <span className="min-w-0 flex-1">{t.text}</span>
          {t.link && (
            <Link to={t.link.to} className="font-medium text-primary hover:text-primary-hover">
              {t.link.label}
            </Link>
          )}
        </li>
      ))}
    </ul>
  )
}
