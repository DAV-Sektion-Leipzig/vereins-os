import { useMemo, useState } from 'react'
import { ArrowLeftIcon, ArrowLeftRightIcon, MessageSquareTextIcon, PrinterIcon, Undo2Icon } from 'lucide-react'
import { Link, useLoaderData } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { useDsAccess } from '@/features/ds/access'
import { dashboardHref, previewOf, type Booking, type ItemData } from '@/features/ds/budget/data'
import { DataStand, PrintHeader, prevDateOf } from '@/features/ds/budget/DashboardPage'
import { DecideDialog, NoteDialog, ReallocDialog, RekeyDialog } from '@/features/ds/budget/dialogs'
import { AmpelBadge, BlockHeading, BudgetBar, euro, euroCents, PrevYear, PrintLandscape, Tile } from '@/features/ds/budget/ui'
import { DS_MESSAGES } from '@/features/ds/errors'
import { LoadFailed } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime } from '@/lib/format'

type SortKey = 'date' | 'account' | 'amount'

const REQUEST_STATUS: Record<string, string> = {
  requested: 'beantragt',
  proposed: 'vorgeschlagen',
  confirmed: 'bestätigt',
  accepted: 'angenommen',
  rejected: 'abgelehnt',
  withdrawn: 'zurückgezogen',
  obsolete: 'gegenstandslos',
}

// US-DS-09, -14, US-FI-27: Summe je Konto, Einzelbuchungen (sortier- und durchsuchbar), Etiketten, Hinweis-Verlauf,
// Umschichtungen des Postens. Ohne Recht auf Einzelbuchungen nur Summen.
export function PostenPage() {
  const data = useLoaderData() as ItemData
  const { item, year, head, siblings, all, bookings, accounts, notes, requests, failed } = data
  const { maintain } = useDsAccess()
  const [search, setSearch] = useState('')
  const [sort, setSort] = useState<SortKey>('date')
  const [rekey, setRekey] = useState<Booking | null>(null)
  const [undo, setUndo] = useState<Booking | null>(null)
  const [note, setNote] = useState(false)
  const [realloc, setRealloc] = useState(false)

  const visible = useMemo(() => {
    const q = search.trim().toLowerCase()
    const list = (bookings ?? []).filter(
      (b) =>
        q === '' ||
        [b.account, b.booking_text, b.receipt, b.contra_label, formatDate(b.booking_date), euroCents(b.amount)]
          .some((v) => (v ?? '').toLowerCase().includes(q)),
    )
    return [...list].sort((a, b) =>
      sort === 'amount' ? Number(b.amount) - Number(a.amount) : sort === 'account' ? a.account.localeCompare(b.account) : b.booking_date.localeCompare(a.booking_date),
    )
  }, [bookings, search, sort])

  if (!item) {
    return (
      <div className="flex flex-col gap-3">
        <BackLink year={year} />
        {failed ? <LoadFailed /> : <p className="text-sm text-muted-foreground">{DS_MESSAGES.itemUnknown}</p>}
      </div>
    )
  }

  const preview = previewOf(item)
  const isIncome = item.kind === 'income'
  const sum = visible.reduce((s, b) => s + Number(b.amount), 0)

  return (
    <div className="flex flex-col gap-6">
      <PrintLandscape />
      <PrintHeader title={`${item.group_name} · ${item.name} · ${year}`} head={head} />
      <div className="flex flex-col gap-2 print:hidden">
        <BackLink year={year} referatId={item.referat_id} />
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div className="flex flex-col gap-0.5">
            <p className="text-sm text-muted-foreground">
              {item.group_name} · {isIncome ? 'Einnahme' : 'Ausgabe'}
            </p>
            <h1 className="text-xl font-semibold">{item.name}</h1>
          </div>
          <div className="flex flex-wrap gap-2">
            {item.can_edit && (
              <Button variant="outline" onClick={() => setNote(true)}>
                <MessageSquareTextIcon data-icon="inline-start" aria-hidden="true" />
                Hinweis eintragen
              </Button>
            )}
            {item.can_edit && !isIncome && (
              <Button variant="outline" onClick={() => setRealloc(true)}>
                <ArrowLeftRightIcon data-icon="inline-start" aria-hidden="true" />
                {maintain ? 'Umschichten' : 'Umschichtung beantragen'}
              </Button>
            )}
            <Button variant="outline" onClick={() => window.print()}>
              <PrinterIcon data-icon="inline-start" aria-hidden="true" />
              Drucken
            </Button>
          </div>
        </div>
        <DataStand head={head} year={year} />
      </div>

      {failed && <LoadFailed />}

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <Tile label="Plan (aktuell)" value={euro(item.plan_current)}>
          beschlossen {euro(item.plan_decided)}
        </Tile>
        <Tile label={isIncome ? 'erreicht' : 'verbraucht'} value={euro(item.actual)}>
          <PrevYear value={item.actual_prev_same_day} current={Number(item.actual)} found={item.prev_found} date={prevDateOf(head)} />
          {item.prev_found && item.actual_prev_full !== null && ` · ganzes Vorjahr ${euro(item.actual_prev_full)}`}
        </Tile>
        <Tile label={isIncome ? 'fehlt noch' : 'frei'} value={euro(isIncome ? Math.max(Number(item.plan_current) - Number(item.actual), 0) : Number(item.plan_current) - Number(item.actual))}>
          {preview > 0 && `Vorschau: ${euro(preview)} abgerechnet, noch nicht gebucht`}
        </Tile>
        <Tile label="Verbrauch" value={item.pct === null ? '–' : `${Math.round(Number(item.pct))} %`}>
          {!isIncome && <AmpelBadge ampel={item.ampel} />}
        </Tile>
      </div>
      <BudgetBar
        plan={Number(item.plan_current)}
        actual={Number(item.actual)}
        preview={preview}
        progress={head?.progress ?? null}
        ampel={isIncome ? 'ok' : item.ampel}
        label={`${euro(item.actual)} von ${euro(item.plan_current)}`}
      />
      {preview > 0 && (
        <p className="text-sm text-status-invited">
          Vorschau aus Finanzen: {euro(item.preview_runs)} in freigegebenen Auszahlungsrunden
          {Number(item.preview_settlements ?? 0) > 0 && `, ${euro(item.preview_settlements)} in abgeschlossenen Abrechnungen`} – noch nicht gebucht, nicht im Ist.
        </p>
      )}

      <section aria-labelledby="notes-heading" className="flex flex-col gap-2">
        <BlockHeading id="notes-heading">Hinweis</BlockHeading>
        {notes.length === 0 ? (
          <p className="text-sm text-muted-foreground">Kein Hinweis.</p>
        ) : (
          <ul className="flex flex-col gap-1.5 text-sm">
            {notes.map((n) => (
              <li key={n.id} className={n.valid_to ? 'text-muted-foreground' : ''}>
                <span className="text-xs text-muted-foreground">{formatDateTime(n.created_at)}{n.valid_to ? ' · ersetzt' : ''}: </span>
                {n.text}
              </li>
            ))}
          </ul>
        )}
      </section>

      {requests.length > 0 && (
        <section aria-labelledby="req-heading" className="flex flex-col gap-2">
          <BlockHeading id="req-heading">Umschichtungen und Vorschläge</BlockHeading>
          <ul className="flex flex-col divide-y rounded-xl border text-sm">
            {requests.map((r) => (
              <li key={r.id} className="flex flex-wrap gap-x-3 px-3 py-2">
                <span className="font-medium">{r.request_type === 'reallocation' ? 'Umschichtung' : 'Vorschlag'}</span>
                <span>
                  {r.from_name ?? '–'} → {r.to_name}, {euro(r.amount)}
                </span>
                <span className="text-muted-foreground">
                  {REQUEST_STATUS[r.status] ?? r.status} · {r.reason}
                </span>
              </li>
            ))}
          </ul>
        </section>
      )}

      <section aria-labelledby="bookings-heading" className="flex flex-col gap-3">
        <BlockHeading id="bookings-heading">Summe je Konto und Einzelbuchungen</BlockHeading>
        {bookings === null ? (
          <p className="text-sm text-muted-foreground">{DS_MESSAGES.bookingsHidden}</p>
        ) : (
          <>
            {accounts.length > 0 && (
              <div className="overflow-x-auto rounded-xl border">
                <Table>
                  <TableHeader>
                    <TableRow className="bg-muted hover:bg-muted">
                      <TableHead className="pl-4">Konto</TableHead>
                      <TableHead>Bezeichnung</TableHead>
                      <TableHead className="text-right">Buchungen</TableHead>
                      <TableHead className="pr-4 text-right">Betrag</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {accounts.map((a) => (
                      <TableRow key={a.account}>
                        <TableCell className="pl-4 tabular-nums">{a.account}</TableCell>
                        <TableCell>{a.account_label ?? '–'}</TableCell>
                        <TableCell className="text-right tabular-nums">{a.bookings}</TableCell>
                        <TableCell className="pr-4 text-right tabular-nums">{euroCents(a.amount)}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center print:hidden">
              <Input
                type="search"
                aria-label="Einzelbuchungen durchsuchen"
                placeholder="Suche: Text, Beleg, Konto, Betrag"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="sm:max-w-72"
              />
              <span className="text-sm text-muted-foreground">
                {visible.length} Buchung{visible.length === 1 ? '' : 'en'} · Summe {euroCents(sum)}
              </span>
            </div>
            {visible.length === 0 ? (
              <p className="text-sm text-muted-foreground">Keine Einzelbuchungen.</p>
            ) : (
              <div className="overflow-x-auto rounded-xl border">
                <Table className="min-w-[44rem]">
                  <TableHeader>
                    <TableRow className="bg-muted hover:bg-muted">
                      <SortHead label="Datum" active={sort === 'date'} onClick={() => setSort('date')} className="pl-4" />
                      <SortHead label="Konto" active={sort === 'account'} onClick={() => setSort('account')} />
                      <TableHead>Buchungstext</TableHead>
                      <TableHead>Beleg</TableHead>
                      <SortHead label="Betrag" active={sort === 'amount'} onClick={() => setSort('amount')} className="text-right" />
                      <TableHead className="pr-4 print:hidden">
                        <span className="sr-only">Aktionen</span>
                      </TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {visible.map((b) => (
                      <TableRow key={b.booking_id}>
                        <TableCell className="pl-4 tabular-nums">{formatDate(b.booking_date)}</TableCell>
                        <TableCell className="tabular-nums">{b.account}</TableCell>
                        <TableCell className="max-w-80 whitespace-normal">
                          {b.booking_text ?? '–'}
                          <span className="flex flex-wrap gap-1">
                            {b.rekeyed && (
                              <span title={b.rekey_info ?? undefined} className="rounded-md border border-dashed border-status-invited px-1.5 text-xs font-medium text-status-invited">
                                umgeschlüsselt{b.rekey_info ? `: ${b.rekey_info}` : ''}
                              </span>
                            )}
                            {b.proposal_open && (
                              <span className="rounded-md bg-status-locked-bg px-1.5 text-xs font-medium text-status-locked">Vorschlag offen</span>
                            )}
                          </span>
                        </TableCell>
                        <TableCell>{b.receipt ?? '–'}</TableCell>
                        <TableCell className="text-right tabular-nums">{euroCents(b.amount)}</TableCell>
                        <TableCell className="pr-4 text-right print:hidden">
                          {maintain && b.rekeyed ? (
                            <Button variant="ghost" size="sm" onClick={() => setUndo(b)}>
                              <Undo2Icon data-icon="inline-start" aria-hidden="true" />
                              Zurücknehmen
                            </Button>
                          ) : (maintain || (item.can_edit && !b.proposal_open)) ? (
                            <Button variant="ghost" size="sm" onClick={() => setRekey(b)}>
                              <ArrowLeftRightIcon data-icon="inline-start" aria-hidden="true" />
                              {maintain ? 'Umschlüsseln' : 'Vorschlagen'}
                            </Button>
                          ) : null}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </>
        )}
      </section>

      {note && <NoteDialog item={item} onClose={() => setNote(false)} />}
      {realloc && <ReallocDialog items={siblings} from={item} direct={maintain} onClose={() => setRealloc(false)} />}
      {rekey && <RekeyDialog booking={rekey} item={item} items={all} maintain={maintain} onClose={() => setRekey(null)} />}
      {undo && (
        <DecideDialog
          title="Umschlüsselung zurücknehmen"
          description={`${formatDate(undo.booking_date)} · ${undo.booking_text ?? '–'} · ${euroCents(undo.amount)}. Die Buchung zählt danach wieder nach der Zuordnungsregel ihres Kontos.`}
          fn="fi_budget_rekey_undo"
          args={() => ({ p_rule: undo.rule_id })}
          reasonRequired={false}
          submitLabel="Zurücknehmen"
          success="Umschlüsselung zurückgenommen."
          onClose={() => setUndo(null)}
        />
      )}
    </div>
  )
}

function BackLink({ year, referatId }: { year: number; referatId?: string | null }) {
  return (
    <Link
      to={dashboardHref(year, referatId ? { kind: 'referat', referatId } : { kind: 'verein' })}
      className="inline-flex items-center gap-1 self-start text-sm text-primary hover:text-primary-hover"
    >
      <ArrowLeftIcon aria-hidden="true" className="size-4" />
      Zum Dashboard
    </Link>
  )
}

function SortHead({ label, active, onClick, className }: { label: string; active: boolean; onClick: () => void; className?: string }) {
  return (
    <TableHead className={className} aria-sort={active ? (label === 'Konto' ? 'ascending' : 'descending') : undefined}>
      <button type="button" onClick={onClick} className={active ? 'font-semibold underline underline-offset-4' : 'hover:underline'}>
        {label}
      </button>
    </TableHead>
  )
}
