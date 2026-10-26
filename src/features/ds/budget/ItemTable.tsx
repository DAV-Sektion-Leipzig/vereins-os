// Zeilen je Budgetposten (Skizze „Dashboard Kinder und Jugend“, Block ②): Plan, verbraucht mit Vorjahr, Balken mit
// Jahresfortschritt und Vorschau, Ampel, Hinweis. Ab 640 px als Raster, darunter als Karten.
import { FileTextIcon, MessageSquareTextIcon } from 'lucide-react'
import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { previewOf, type OverviewItem } from '@/features/ds/budget/data'
import { AmpelBadge, BudgetBar, euro, PreviewOverBadge, PrevYear } from '@/features/ds/budget/ui'
import { cn } from '@/lib/utils'

type Props = {
  items: OverviewItem[]
  progress: number | null
  prevDate?: string
  /** Gesamtbudget vor dem Postennamen zeigen (mehrere Gesamtbudgets in der Liste). */
  showGroup?: boolean
  onNote?: (item: OverviewItem) => void
}

const COLS = 'sm:grid-cols-[minmax(10rem,1.6fr)_6.5rem_8.5rem_minmax(8rem,1.4fr)_7.5rem_minmax(9rem,1.6fr)]'

export function ItemTable({ items, progress, prevDate, showGroup = false, onNote }: Props) {
  const expense = items.filter((i) => i.kind === 'expense')
  const income = items.filter((i) => i.kind === 'income')
  return (
    <div className="flex flex-col gap-4">
      {expense.length > 0 && <Rows title="Ausgaben" items={expense} progress={progress} prevDate={prevDate} showGroup={showGroup} onNote={onNote} />}
      {income.length > 0 && <Rows title="Einnahmen" items={income} progress={progress} prevDate={prevDate} showGroup={showGroup} onNote={onNote} />}
    </div>
  )
}

function Rows({ title, items, progress, prevDate, showGroup, onNote }: Props & { title: string }) {
  const isIncome = items[0]?.kind === 'income'
  return (
    <div className="overflow-hidden rounded-xl border" role="table" aria-label={title}>
      <div role="row" className={cn('hidden gap-3 border-b bg-muted px-3 py-2 text-sm font-medium sm:grid', COLS)}>
        <span role="columnheader">{title}</span>
        <span role="columnheader" className="text-right">
          Plan
        </span>
        <span role="columnheader" className="text-right">
          {isIncome ? 'erreicht' : 'verbraucht'}
        </span>
        <span role="columnheader">Verlauf</span>
        <span role="columnheader">{isIncome ? 'fehlt noch' : 'Ampel'}</span>
        <span role="columnheader">Hinweis</span>
      </div>
      {items.map((item) => (
        <Row key={item.item_id} item={item} progress={progress} prevDate={prevDate} showGroup={showGroup} onNote={onNote} />
      ))}
    </div>
  )
}

function Row({ item, progress, prevDate, showGroup, onNote }: { item: OverviewItem; progress: number | null; prevDate?: string; showGroup?: boolean; onNote?: (item: OverviewItem) => void }) {
  const preview = previewOf(item)
  const isIncome = item.kind === 'income'
  const overWithPreview = !isIncome && preview > 0 && Number(item.actual) + preview > Number(item.plan_current)
  return (
    <div role="row" className={cn('grid grid-cols-2 gap-x-3 gap-y-2 border-b px-3 py-2.5 last:border-b-0 sm:items-center', COLS)}>
      <div role="cell" className="col-span-2 flex min-w-0 flex-col sm:col-span-1">
        <Link to={`/dashboard/budget/posten/${item.item_id}`} className="truncate font-medium text-primary hover:text-primary-hover">
          {showGroup ? `${item.group_name} · ` : ''}
          {item.name}
        </Link>
        <span className="flex flex-wrap gap-x-2 text-xs text-muted-foreground">
          {item.status_uncertain && <span title="Die Zuordnung zu diesem Posten ist unsicher oder offen.">? Zuordnung unsicher</span>}
          {item.no_booking && <span>keine Buchung</span>}
          {item.open_reallocations > 0 && <span>{item.open_reallocations} Umschichtung offen</span>}
          {item.open_proposals > 0 && <span>{item.open_proposals} Vorschlag offen</span>}
        </span>
      </div>
      <div role="cell" className="text-sm tabular-nums sm:text-right">
        <span className="text-muted-foreground sm:hidden">Plan </span>
        {euro(item.plan_current)}
        {item.plan_decided !== null && Number(item.plan_decided) !== Number(item.plan_current) && (
          <span className="block text-xs text-muted-foreground">beschlossen {euro(item.plan_decided)}</span>
        )}
      </div>
      <div role="cell" className="flex flex-col text-sm tabular-nums sm:items-end">
        <span>
          <span className="text-muted-foreground sm:hidden">{isIncome ? 'erreicht ' : 'verbraucht '}</span>
          {euro(item.actual)}
        </span>
        <PrevYear value={item.actual_prev_same_day} current={Number(item.actual)} found={item.prev_found} date={prevDate} />
      </div>
      <div role="cell" className="col-span-2 flex flex-col gap-1 sm:col-span-1">
        <BudgetBar
          plan={Number(item.plan_current)}
          actual={Number(item.actual)}
          preview={preview}
          progress={progress}
          ampel={isIncome ? 'ok' : item.ampel}
          label={`${item.name}: ${euro(item.actual)} von ${euro(item.plan_current)}${preview > 0 ? `, Vorschau ${euro(preview)}` : ''}`}
        />
        {preview > 0 && (
          <span
            className="self-start rounded-md border border-dashed border-status-invited px-1.5 text-xs font-medium text-status-invited"
            title="Aus Finanzen: abgerechnet bzw. ausgezahlt, noch nicht gebucht. Zählt nicht zu verbraucht, frei oder Ampel."
          >
            Vorschau +{euro(preview)} · nicht im Ist
          </span>
        )}
      </div>
      <div role="cell" className="flex flex-wrap items-center gap-1">
        {isIncome ? (
          <span className="text-sm tabular-nums">{item.no_booking ? '–' : euro(Math.max(Number(item.plan_current) - Number(item.actual), 0))}</span>
        ) : (
          <>
            <AmpelBadge ampel={item.ampel} />
            {overWithPreview && <PreviewOverBadge />}
          </>
        )}
      </div>
      <div role="cell" className="col-span-2 flex items-start gap-1 sm:col-span-1">
        <span className="min-w-0 flex-1 text-sm break-words">
          {item.note ?? <span className="text-muted-foreground">–</span>}
        </span>
        <span className="flex shrink-0 gap-0.5 print:hidden">
          {onNote && item.can_edit && (
            <Button variant="ghost" size="icon-sm" aria-label={`Hinweis zu ${item.name}`} title="Hinweis eintragen" onClick={() => onNote(item)}>
              <MessageSquareTextIcon aria-hidden="true" />
            </Button>
          )}
          {item.can_see_bookings && (
            <Button asChild variant="ghost" size="icon-sm" title="Einzelbuchungen">
              <Link to={`/dashboard/budget/posten/${item.item_id}`} aria-label={`Einzelbuchungen ${item.name}`}>
                <FileTextIcon aria-hidden="true" />
              </Link>
            </Button>
          )}
        </span>
      </div>
    </div>
  )
}
