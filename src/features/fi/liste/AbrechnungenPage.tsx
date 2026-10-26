import { useState } from 'react'
import { CalculatorIcon, CheckIcon, CircleDashedIcon, FileDownIcon, LockIcon, TimerOffIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Pagination } from '@/components/Pagination'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { useFiAccess } from '@/features/fi/access'
import { FI_MESSAGES } from '@/features/fi/errors'
import { downloadSettlementDocuments } from '@/features/fi/export/documents'
import { formatMoney, halfKey, halfLabel, halfOptions, parseHalf, STATUS_LABELS, STATUSES, type SettlementStatus } from '@/features/fi/labels'
import { listHref, type GroupOption, type ListFilter, type ListResult, type SettlementRow } from '@/features/fi/liste/data'
import { fiRpc } from '@/features/fi/rpc'
import { HintBadges, StatusBadge } from '@/features/fi/shared/ui'
import { LoadFailed, selectClassName } from '@/features/gr/shared/ui'

type Action = 'calculate' | 'confirm' | 'close' | 'expire' | null

type CalcResult = { created: number; recalculated: number; unchanged: number; locked: number; removed: number }

// FT11 (US-FI-01, -05, -06, -08, -10, -12): Abrechnungen eines Halbjahres mit Filtern, 50 je Seite, mobil als Karten;
// Mehrfachauswahl für bestätigen (Referent:in) bzw. abschließen, Abrechnungsdokumente, verfallen (Geschäftsstelle).
export function AbrechnungenPage() {
  const { filter, rows, total, groups, failed } = useLoaderData() as ListResult
  const { canManage, confirmReferate } = useFiAccess()
  const canConfirm = confirmReferate.length > 0
  const revalidator = useRevalidator()
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [action, setAction] = useState<Action>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Auswahl gilt nur für sichtbare Zeilen (nach Filter- oder Seitenwechsel)
  const visible = rows.filter((r) => selected.has(r.id))
  const names = Object.fromEntries(rows.map((r) => [r.id, r.display_name]))
  const selectable = canManage || canConfirm

  function toggle(id: string, on: boolean) {
    setSelected((s) => {
      const next = new Set(s)
      if (on) next.add(id)
      else next.delete(id)
      return next
    })
  }

  function close() {
    setAction(null)
    setError(null)
  }

  async function run() {
    setPending(true)
    setError(null)
    const ids = visible.map((r) => r.id)
    if (action === 'calculate') {
      const res = await fiRpc<CalcResult>('fi_calculate_half', { p_year: filter.half.year, p_half: filter.half.half })
      setPending(false)
      if (res.error) return setError(res.error.text)
      const r = res.data
      toast.success(
        `Berechnet: ${r.created} neu angelegt, ${r.recalculated} neu berechnet, ${r.unchanged} unverändert` +
          (r.locked ? `, ${r.locked} abgeschlossen (nicht neu berechnet)` : '') +
          (r.removed ? `, ${r.removed} ohne Positionen entfernt` : '') +
          '.',
      )
    } else {
      const fn = action === 'confirm' ? 'fi_confirm' : action === 'close' ? 'fi_close' : 'fi_expire'
      const res = await fiRpc(fn, { p_ids: ids }, names)
      setPending(false)
      if (res.error) return setError(res.error.text)
      toast.success(
        action === 'confirm'
          ? `${ids.length} Abrechnung(en) bestätigt.`
          : action === 'close'
            ? `${ids.length} Abrechnung(en) abgeschlossen.`
            : `${ids.length} Abrechnung(en) als verfallen erfasst.`,
      )
    }
    setSelected(new Set())
    close()
    revalidator.revalidate()
  }

  async function documents() {
    setPending(true)
    const result = await downloadSettlementDocuments(visible.map((r) => r.id), filter.half, names)
    setPending(false)
    if (result) toast.error(result)
  }

  const columns: Column<SettlementRow>[] = [
    ...(selectable
      ? [
          {
            key: 'select',
            header: (
              <input
                type="checkbox"
                aria-label="Alle auf dieser Seite auswählen"
                checked={rows.length > 0 && visible.length === rows.length}
                onChange={(e) => setSelected(e.target.checked ? new Set(rows.map((r) => r.id)) : new Set())}
                className="size-5 accent-primary"
              />
            ),
            cell: (r: SettlementRow) => (
              <input
                type="checkbox"
                aria-label={`${r.display_name} auswählen`}
                checked={selected.has(r.id)}
                onChange={(e) => toggle(r.id, e.target.checked)}
                className="size-5 accent-primary"
              />
            ),
            className: 'w-10',
          },
        ]
      : []),
    {
      key: 'name',
      header: 'Name',
      cell: (r) => (
        <Link to={`/fi/abrechnung/${r.id}`} className="font-medium underline-offset-4 hover:underline">
          {r.display_name}
        </Link>
      ),
    },
    { key: 'groups', header: 'Gruppe', cell: (r) => <span className="text-sm">{r.groups.join(', ')}</span> },
    { key: 'amount', header: 'Betrag', cell: (r) => formatMoney(r.amount), className: 'text-right tabular-nums', headerClassName: 'text-right' },
    { key: 'status', header: 'Zustand', cell: (r) => <StatusBadge status={r.status} /> },
    { key: 'hints', header: 'Hinweise', cell: (r) => <HintBadges hints={r.hints} year={filter.half.year} /> },
    { key: 'confirm', header: 'Bestätigung', cell: (r) => <Confirmations row={r} /> },
  ]

  const dialog: Record<Exclude<Action, null>, { title: string; text: string; label: string; pendingLabel: string }> = {
    calculate: {
      title: `${halfLabel(filter.half)} berechnen?`,
      text: 'Entwürfe und bestätigte Abrechnungen werden aus der Anwesenheitserfassung neu berechnet. Korrekturen bleiben erhalten; ändert sich eine bestätigte Abrechnung, fällt die Bestätigung zurück. Abgeschlossene Abrechnungen bleiben unverändert.',
      label: 'Berechnen',
      pendingLabel: 'Wird berechnet …',
    },
    confirm: {
      title: `${visible.length} Abrechnung(en) bestätigen?`,
      text: 'Du bestätigst die Positionen deiner Referate als sachlich richtig.',
      label: 'Bestätigen',
      pendingLabel: 'Wird bestätigt …',
    },
    close: {
      title: `${visible.length} Abrechnung(en) abschließen?`,
      text: 'Danach sind die abgerechneten Anwesenheiten in der Anwesenheitserfassung gesperrt. Das Abrechnungsdokument kann gedruckt werden.',
      label: 'Abschließen',
      pendingLabel: 'Wird abgeschlossen …',
    },
    expire: {
      title: `${visible.length} Abrechnung(en) als verfallen erfassen?`,
      text: 'Die Frist ist abgelaufen, die Abrechnungen wurden nicht abgegeben. Verfallene Abrechnungen werden nicht ausgezahlt.',
      label: 'Verfallen',
      pendingLabel: 'Wird gespeichert …',
    },
  }

  return (
    <section className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Abrechnungen {halfLabel(filter.half)}</h1>
        {canManage && (
          <Button onClick={() => setAction('calculate')}>
            <CalculatorIcon data-icon="inline-start" aria-hidden="true" />
            Berechnen
          </Button>
        )}
      </div>

      <FilterForm key={listHref(filter)} filter={filter} groups={groups} canConfirm={canConfirm} canManage={canManage} />

      {selectable && rows.length > 0 && (
        <div className="flex flex-wrap items-center gap-2 rounded-xl border bg-muted/40 p-2">
          <span className="px-1 text-sm text-muted-foreground tabular-nums">{visible.length} ausgewählt</span>
          {canConfirm && (
            <Button variant="outline" size="sm" disabled={visible.length === 0} onClick={() => setAction('confirm')}>
              <CheckIcon data-icon="inline-start" aria-hidden="true" />
              Bestätigen
            </Button>
          )}
          {canManage && (
            <>
              <Button variant="outline" size="sm" disabled={visible.length === 0} onClick={() => setAction('close')}>
                <LockIcon data-icon="inline-start" aria-hidden="true" />
                Abschließen
              </Button>
              <Button variant="outline" size="sm" disabled={visible.length === 0 || pending} onClick={documents}>
                <FileDownIcon data-icon="inline-start" aria-hidden="true" />
                Abrechnungsdokumente
              </Button>
              <Button variant="outline" size="sm" disabled={visible.length === 0} onClick={() => setAction('expire')}>
                <TimerOffIcon data-icon="inline-start" aria-hidden="true" />
                Verfallen
              </Button>
            </>
          )}
        </div>
      )}

      {failed ? (
        <LoadFailed />
      ) : (
        <>
          <ResponsiveTable
            rows={rows}
            rowKey={(r) => r.id}
            columns={columns}
            card={(r) => (
              <SettlementCard
                row={r}
                year={filter.half.year}
                selectable={selectable}
                selected={selected.has(r.id)}
                onToggle={(on) => toggle(r.id, on)}
              />
            )}
            empty={FI_MESSAGES.emptyHalf}
            caption={`Abrechnungen ${halfLabel(filter.half)}`}
          />
          <Pagination page={filter.page} total={total} href={(page) => listHref({ ...filter, page })} label="Abrechnungen" />
        </>
      )}

      {action && (
        <ConfirmDialog
          title={dialog[action].title}
          confirmLabel={dialog[action].label}
          pendingLabel={dialog[action].pendingLabel}
          pending={pending}
          error={error}
          destructive={action === 'expire'}
          onConfirm={run}
          onClose={close}
        >
          {dialog[action].text}
        </ConfirmDialog>
      )}
    </section>
  )
}

function Confirmations({ row }: { row: SettlementRow }) {
  if (!row.referate?.length) return null
  return (
    <ul className="flex flex-col gap-0.5 text-sm">
      {row.referate.map((r) => (
        <li key={r.referat_id} className="flex items-center gap-1.5">
          {r.confirmed ? (
            <CheckIcon className="size-4 text-primary" aria-hidden="true" />
          ) : (
            <CircleDashedIcon className="size-4 text-muted-foreground" aria-hidden="true" />
          )}
          <span>
            {r.name}
            <span className="sr-only">{r.confirmed ? ': bestätigt' : ': nicht bestätigt'}</span>
          </span>
        </li>
      ))}
    </ul>
  )
}

function SettlementCard({
  row,
  year,
  selectable,
  selected,
  onToggle,
}: {
  row: SettlementRow
  year: number
  selectable: boolean
  selected: boolean
  onToggle: (on: boolean) => void
}) {
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-start gap-3">
          {selectable && (
            <input
              type="checkbox"
              aria-label={`${row.display_name} auswählen`}
              checked={selected}
              onChange={(e) => onToggle(e.target.checked)}
              className="mt-0.5 size-5 accent-primary"
            />
          )}
          <span className="flex flex-col">
            <Link to={`/fi/abrechnung/${row.id}`} className="font-medium underline-offset-4 hover:underline">
              {row.display_name}
            </Link>
            <span className="text-sm text-muted-foreground">{row.groups.join(', ')}</span>
          </span>
        </div>
        <span className="font-medium tabular-nums">{formatMoney(row.amount)}</span>
      </div>
      <div className="flex flex-wrap gap-1.5">
        <StatusBadge status={row.status} />
      </div>
      <HintBadges hints={row.hints} year={year} />
      <Confirmations row={row} />
    </div>
  )
}

function FilterForm({
  filter,
  groups,
  canConfirm,
  canManage,
}: {
  filter: ListFilter
  groups: GroupOption[]
  canConfirm: boolean
  canManage: boolean
}) {
  const navigate = useNavigate()
  const set = (patch: Partial<ListFilter>) => navigate(listHref({ ...filter, page: 1, ...patch }), { replace: true })
  const toggles: { key: 'withHint' | 'toConfirm' | 'deadlinePassed'; label: string; show: boolean }[] = [
    { key: 'withHint', label: 'mit Hinweis', show: true },
    { key: 'toConfirm', label: 'zu bestätigen', show: canConfirm },
    { key: 'deadlinePassed', label: 'Frist abgelaufen', show: canManage },
  ]

  return (
    <form role="search" onSubmit={(e) => e.preventDefault()} className="flex flex-col gap-4 sm:flex-row sm:flex-wrap sm:items-end">
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-half">Halbjahr</Label>
        <select
          id="fi-half"
          value={halfKey(filter.half)}
          onChange={(e) => set({ half: parseHalf(e.target.value) ?? filter.half, group: '' })}
          className={selectClassName}
        >
          {halfOptions().map((h) => (
            <option key={halfKey(h)} value={halfKey(h)}>
              {halfLabel(h)}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-status">Zustand</Label>
        <select
          id="fi-status"
          value={filter.status}
          onChange={(e) => set({ status: e.target.value as SettlementStatus | '' })}
          className={selectClassName}
        >
          <option value="">alle</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {STATUS_LABELS[s]}
            </option>
          ))}
        </select>
      </div>
      {groups.length > 0 && (
        <div className="flex flex-col gap-2">
          <Label htmlFor="fi-group">Gruppe</Label>
          <select id="fi-group" value={filter.group} onChange={(e) => set({ group: e.target.value })} className={selectClassName}>
            <option value="">alle</option>
            {groups.map((g) => (
              <option key={g.id} value={g.id}>
                {g.name}
              </option>
            ))}
          </select>
        </div>
      )}
      <div className="flex flex-wrap gap-2">
        {toggles
          .filter((t) => t.show)
          .map((t) => (
            <label key={t.key} className="flex min-h-11 cursor-pointer items-center gap-2 rounded-lg border px-3 text-sm sm:min-h-8">
              <input
                type="checkbox"
                checked={filter[t.key]}
                onChange={(e) => set({ [t.key]: e.target.checked })}
                className="size-4 accent-primary"
              />
              {t.label}
            </label>
          ))}
      </div>
    </form>
  )
}
