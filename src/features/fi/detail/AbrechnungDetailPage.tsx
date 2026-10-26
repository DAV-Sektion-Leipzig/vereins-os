import { useState, type ReactNode } from 'react'
import {
  CheckIcon,
  CircleDashedIcon,
  FileDownIcon,
  FileSignatureIcon,
  LockIcon,
  PencilIcon,
  RotateCcwIcon,
  TimerOffIcon,
  UserCheckIcon,
} from 'lucide-react'
import { Link, useLoaderData, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { formatEventDate } from '@/features/ez/dates'
import { KIND_LABELS, ROLE_LABELS, type EventKind } from '@/features/ez/labels'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import type { Confirmation, DetailResult, Item, SettlementDetail } from '@/features/fi/detail/data'
import { FI_MESSAGES } from '@/features/fi/errors'
import { downloadSettlementDocuments } from '@/features/fi/export/documents'
import {
  formatMoney,
  formatQuantity,
  hintLabel,
  LOG_LABELS,
  POSITION_LABELS,
  RATE_ROLE_LABELS,
  type RateRole,
} from '@/features/fi/labels'
import { fiRpc } from '@/features/fi/rpc'
import { FormDialog } from '@/features/fi/shared/FormDialog'
import { HintBadges, StatusBadge, textareaClassName } from '@/features/fi/shared/ui'
import { selectClassName } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime, todayIso } from '@/lib/format'

type Dialog =
  | { kind: 'correct'; item: Item }
  | { kind: 'exception'; item: Item }
  | { kind: 'substitute'; confirmation: Confirmation }
  | { kind: 'submit' }
  | { kind: 'confirm' | 'close' | 'reopen' | 'expire' }
  | null

const REASON_MAX = 500

// FT12 (US-FI-02 bis -12): Kopf mit Zustand, Betrag, Hinweisen und Bestätigungen; Positionen je Gruppe mit
// Zwischensumme; Verlauf. Geschäftsstelle: korrigieren, in Vertretung bestätigen, abschließen, Abrechnungsdokument,
// Abschluss zurücknehmen, Abgabe erfassen, verfallen. Referent:in: Ausnahme begründen, bestätigen.
export function AbrechnungDetailPage() {
  const result = useLoaderData() as DetailResult
  if (!result.detail) {
    return (
      <section className="flex flex-col gap-4">
        <h1 className="text-xl font-semibold">Abrechnung</h1>
        <p role="alert" className="text-sm text-muted-foreground">
          {result.notFound ? FI_MESSAGES.notFound : 'Etwas ist schiefgelaufen. Bitte versuche es erneut.'}
        </p>
        <Button variant="outline" asChild className="self-start">
          <Link to="/fi">Zur Liste</Link>
        </Button>
      </section>
    )
  }
  return <Detail key={result.detail.settlement.id} detail={result.detail} />
}

function Detail({ detail }: { detail: SettlementDetail }) {
  const { settlement: s, info, items, confirmations, log, can_manage: canManage } = detail
  const revalidator = useRevalidator()
  const [dialog, setDialog] = useState<Dialog>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [downloading, setDownloading] = useState(false)

  const editable = s.status === 'draft' || s.status === 'confirmed'
  const canConfirmOwn = s.status === 'draft' && confirmations.some((c) => c.can_confirm && !c.confirmed_at)
  const closedOrLater = s.status === 'closed' || s.status === 'submitted' || s.status === 'expired' || s.status === 'paid'
  const deadlinePassed = !!s.deadline && todayIso() > s.deadline

  function close() {
    setDialog(null)
    setError(null)
  }

  /** Aufruf mit Meldung im Dialog; bei Erfolg Hinweis, Dialog zu und neu laden. */
  async function call(name: string, args: Record<string, unknown>, success: string): Promise<boolean> {
    setPending(true)
    setError(null)
    const res = await fiRpc(name, args)
    setPending(false)
    if (res.error) {
      setError(res.error.text)
      return false
    }
    toast.success(success)
    close()
    revalidator.revalidate()
    return true
  }

  async function documents() {
    setDownloading(true)
    const message = await downloadSettlementDocuments([s.id], { year: s.year, half: s.half })
    setDownloading(false)
    if (message) toast.error(message)
  }

  const groups = groupItems(items)
  const maxHint =
    info.hints.includes('max_exceeded') && info.max.limit !== null
      ? `Höchstbetrag überschritten (${formatMoney(info.max.total)} von ${formatMoney(info.max.limit)} im Jahr ${info.max.year})`
      : null
  const headHints = info.hints.filter((h) => h !== 'max_exceeded' && !ITEM_HINTS.has(h))

  const actions: ReactNode[] = []
  if (canConfirmOwn) {
    actions.push(
      <Button key="confirm" onClick={() => setDialog({ kind: 'confirm' })}>
        <CheckIcon data-icon="inline-start" aria-hidden="true" />
        Bestätigen
      </Button>,
    )
  }
  if (canManage && s.status === 'confirmed') {
    actions.push(
      <Button key="close" onClick={() => setDialog({ kind: 'close' })}>
        <LockIcon data-icon="inline-start" aria-hidden="true" />
        Abschließen
      </Button>,
    )
  }
  if (canManage && closedOrLater) {
    actions.push(
      <Button key="doc" variant="outline" onClick={documents} disabled={downloading}>
        <FileDownIcon data-icon="inline-start" aria-hidden="true" />
        {downloading ? 'Wird erzeugt …' : 'Abrechnungsdokument'}
      </Button>,
    )
  }
  if (canManage && s.status === 'closed') {
    actions.push(
      <Button key="submit" onClick={() => setDialog({ kind: 'submit' })}>
        <FileSignatureIcon data-icon="inline-start" aria-hidden="true" />
        Abgabe erfassen
      </Button>,
      <Button key="reopen" variant="outline" onClick={() => setDialog({ kind: 'reopen' })}>
        <RotateCcwIcon data-icon="inline-start" aria-hidden="true" />
        Abschluss zurücknehmen
      </Button>,
    )
    if (deadlinePassed) {
      actions.push(
        <Button key="expire" variant="destructive" onClick={() => setDialog({ kind: 'expire' })}>
          <TimerOffIcon data-icon="inline-start" aria-hidden="true" />
          Verfallen
        </Button>,
      )
    }
  }

  return (
    <section className="flex flex-col gap-6">
      <header className="flex flex-col gap-3">
        <div className="flex flex-col gap-1">
          <Link to={`/fi?hj=${s.year}-${s.half}`} className="text-sm text-muted-foreground underline-offset-4 hover:underline">
            Abrechnungen {s.half}. Halbjahr {s.year}
          </Link>
          <div className="flex flex-wrap items-baseline justify-between gap-3">
            <h1 className="text-xl font-semibold text-balance">{s.display_name}</h1>
            <span className="text-xl font-semibold tabular-nums">{formatMoney(s.amount)}</span>
          </div>
          <div className="flex flex-wrap gap-1.5">
            <StatusBadge status={s.status} />
            {!info.payable && s.status !== 'paid' && <Badge variant="outline">nicht auszahlbar</Badge>}
          </div>
        </div>
        <HintBadges hints={headHints} year={s.year} />
        {maxHint && <HintBadges hints={[maxHint]} />}
        {actions.length > 0 && <div className="flex flex-wrap gap-2">{actions}</div>}
      </header>

      <Facts detail={detail} />

      <section aria-labelledby="fi-confirmations" className="flex flex-col gap-2">
        <h2 id="fi-confirmations" className="text-lg font-semibold">
          Bestätigung (sachlich richtig)
        </h2>
        <ul className="flex flex-col divide-y rounded-xl border">
          {confirmations.map((c) => (
            <li key={c.referat_id} className="flex flex-col gap-2 px-3 py-2.5 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-start gap-2">
                {c.confirmed_at ? (
                  <CheckIcon className="mt-0.5 size-4 shrink-0 text-primary" aria-hidden="true" />
                ) : (
                  <CircleDashedIcon className="mt-0.5 size-4 shrink-0 text-muted-foreground" aria-hidden="true" />
                )}
                <div className="flex flex-col text-sm">
                  <span className="font-medium">{c.referat_name}</span>
                  <span className="text-muted-foreground">
                    {c.confirmed_at
                      ? `bestätigt am ${formatDate(c.confirmed_at)} von ${c.confirmed_by_name ?? 'unbekannt'}${c.is_substitute ? ' in Vertretung' : ''}`
                      : 'noch nicht bestätigt'}
                  </span>
                  {c.substitute_reason && <span className="text-muted-foreground">Begründung: {c.substitute_reason}</span>}
                </div>
              </div>
              {canManage && s.status === 'draft' && !c.confirmed_at && (
                <Button variant="outline" size="sm" onClick={() => setDialog({ kind: 'substitute', confirmation: c })}>
                  <UserCheckIcon data-icon="inline-start" aria-hidden="true" />
                  In Vertretung bestätigen
                </Button>
              )}
            </li>
          ))}
        </ul>
      </section>

      <section aria-labelledby="fi-items" className="flex flex-col gap-4">
        <h2 id="fi-items" className="text-lg font-semibold">
          Positionen
        </h2>
        {groups.map((g) => (
          <div key={g.label} className="flex flex-col gap-2">
            <div className="flex items-baseline justify-between gap-3">
              <h3 className="font-medium">{g.label}</h3>
              <span className="text-sm text-muted-foreground tabular-nums">Zwischensumme {formatMoney(g.total)}</span>
            </div>
            <ul className="flex flex-col divide-y rounded-xl border">
              {g.items.map((i) => (
                <ItemRow
                  key={i.id}
                  item={i}
                  canCorrect={canManage && editable}
                  canException={
                    s.status === 'draft' &&
                    i.hints.includes('no_license') &&
                    (canManage || confirmations.some((c) => c.referat_id === i.referat_id && c.can_confirm))
                  }
                  onCorrect={() => setDialog({ kind: 'correct', item: i })}
                  onException={() => setDialog({ kind: 'exception', item: i })}
                />
              ))}
            </ul>
          </div>
        ))}
      </section>

      <section aria-labelledby="fi-log" className="flex flex-col gap-2">
        <h2 id="fi-log" className="text-lg font-semibold">
          Verlauf
        </h2>
        <ol className="flex flex-col gap-1.5 text-sm">
          {log.map((l, index) => (
            <li key={index} className="flex flex-col sm:flex-row sm:gap-3">
              <span className="shrink-0 text-muted-foreground tabular-nums sm:w-36">{formatDateTime(l.at)}</span>
              <span>
                {LOG_LABELS[l.action] ?? l.action}
                {l.by_name ? ` von ${l.by_name}` : ''}
                {logDetail(l.detail)}
              </span>
            </li>
          ))}
        </ol>
      </section>

      {dialog?.kind === 'confirm' && (
        <ConfirmDialog
          title="Abrechnung bestätigen?"
          confirmLabel="Bestätigen"
          pendingLabel="Wird bestätigt …"
          pending={pending}
          error={error}
          onConfirm={() => call('fi_confirm', { p_ids: [s.id] }, 'Die Abrechnung wurde bestätigt.')}
          onClose={close}
        >
          Du bestätigst die Positionen deiner Referate als sachlich richtig.
        </ConfirmDialog>
      )}
      {dialog?.kind === 'close' && (
        <ConfirmDialog
          title="Abrechnung abschließen?"
          confirmLabel="Abschließen"
          pendingLabel="Wird abgeschlossen …"
          pending={pending}
          error={error}
          onConfirm={() => call('fi_close', { p_ids: [s.id] }, 'Die Abrechnung wurde abgeschlossen.')}
          onClose={close}
        >
          Danach sind die abgerechneten Anwesenheiten in der Anwesenheitserfassung gesperrt. Das Abrechnungsdokument kann
          gedruckt werden.
        </ConfirmDialog>
      )}
      {dialog?.kind === 'reopen' && (
        <ConfirmDialog
          title="Abschluss zurücknehmen?"
          confirmLabel="Zurücknehmen"
          pendingLabel="Wird zurückgenommen …"
          pending={pending}
          error={error}
          onConfirm={() => call('fi_reopen', { p_id: s.id }, 'Der Abschluss wurde zurückgenommen.')}
          onClose={close}
        >
          Die Abrechnung wird wieder zum Entwurf. Alle Bestätigungen entfallen, die Sperre in der Anwesenheitserfassung
          wird aufgehoben.
        </ConfirmDialog>
      )}
      {dialog?.kind === 'expire' && (
        <ConfirmDialog
          title="Abrechnung als verfallen erfassen?"
          confirmLabel="Verfallen"
          pendingLabel="Wird gespeichert …"
          pending={pending}
          error={error}
          destructive
          onConfirm={() => call('fi_expire', { p_ids: [s.id] }, 'Die Abrechnung ist verfallen.')}
          onClose={close}
        >
          Die Frist ist abgelaufen ({s.deadline ? formatDate(s.deadline) : '–'}). Verfallene Abrechnungen werden nicht ausgezahlt.
        </ConfirmDialog>
      )}
      {dialog?.kind === 'correct' && (
        <CorrectDialog item={dialog.item} pending={pending} error={error} onClose={close} call={call} setError={setError} />
      )}
      {dialog?.kind === 'exception' && (
        <ReasonDialog
          title="Ausnahme begründen"
          description="Die Person hat keine förderfähige Lizenz. Begründe, warum der Satz Trainer:in gelten soll. Die Geschäftsstelle korrigiert danach die Satzart."
          initial={dialog.item.exception_reason ?? ''}
          required={false}
          submitLabel="Speichern"
          pending={pending}
          error={error}
          onClose={close}
          onSubmit={(reason) =>
            call('fi_set_exception_reason', { p_item: dialog.item.id, p_reason: reason }, 'Die Begründung wurde gespeichert.')
          }
        />
      )}
      {dialog?.kind === 'substitute' && (
        <ReasonDialog
          title={`In Vertretung bestätigen: ${dialog.confirmation.referat_name}`}
          description="Die Referent:in und ihre Vertretung sind nicht erreichbar. Bitte den Grund angeben."
          initial=""
          required
          submitLabel="Bestätigen"
          pending={pending}
          error={error}
          onClose={close}
          onSubmit={(reason) =>
            call(
              'fi_confirm_substitute',
              { p_id: s.id, p_referat: dialog.confirmation.referat_id, p_reason: reason },
              'In Vertretung bestätigt.',
            )
          }
        />
      )}
      {dialog?.kind === 'submit' && (
        <SubmitDialog settlementId={s.id} deadline={s.deadline} pending={pending} error={error} onClose={close} call={call} setError={setError} />
      )}
    </section>
  )
}

const ITEM_HINTS = new Set(['no_time', 'no_training_time', 'no_license', 'rate_missing'])

function groupItems(items: Item[]) {
  const map = new Map<string, { label: string; total: number; items: Item[] }>()
  for (const i of items) {
    const label = i.group_name ?? i.referat_name
    const g = map.get(label) ?? { label, total: 0, items: [] }
    g.total += Number(i.amount ?? 0)
    g.items.push(i)
    map.set(label, g)
  }
  return [...map.values()].sort((a, b) => a.label.localeCompare(b.label, 'de-DE', { numeric: true }))
}

function logDetail(detail: Record<string, unknown> | null): string {
  if (!detail) return ''
  const reason = detail.reason ?? detail.late_reason
  const date = typeof detail.date === 'string' ? ` (abgegeben am ${formatDate(detail.date)})` : ''
  return `${date}${typeof reason === 'string' && reason ? `: ${reason}` : ''}`
}

function Facts({ detail }: { detail: SettlementDetail }) {
  const { settlement: s, info } = detail
  const rows: [string, ReactNode][] = [
    ['Halbjahr', `${s.half}. Halbjahr ${s.year}`],
    ['Abgabefrist', s.deadline ? formatDate(s.deadline) : '–'],
    ...(s.closed_at ? [['Abgeschlossen', `${formatDateTime(s.closed_at)} von ${s.closed_by_name ?? 'unbekannt'}`] as [string, ReactNode]] : []),
    ...(s.submitted_on ? [['Abgegeben', formatDate(s.submitted_on)] as [string, ReactNode]] : []),
    ...(s.submitted_late_reason ? [['Begründung Abgabe nach Frist', s.submitted_late_reason] as [string, ReactNode]] : []),
    ...(s.expired_at ? [['Verfallen', formatDateTime(s.expired_at)] as [string, ReactNode]] : []),
    ...(s.payout_run_id && detail.can_manage
      ? [['Auszahlungsrunde', <Link key="run" to={`/fi/auszahlungen/${s.payout_run_id}`} className="underline underline-offset-4">Runde öffnen</Link>] as [string, ReactNode]]
      : []),
    ...(!info.payable && s.status !== 'paid'
      ? [['Nicht auszahlbar', info.not_payable_reasons.map((r) => hintLabel(r, s.year)).join(', ')] as [string, ReactNode]]
      : []),
  ]
  return (
    <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
      {rows.map(([label, value]) => (
        <div key={label} className="contents">
          <dt className="text-muted-foreground">{label}</dt>
          <dd className="mb-2 sm:mb-0">{value}</dd>
        </div>
      ))}
    </dl>
  )
}

function dateText(i: Item): string {
  if (i.span === 'multi' && i.end_date) return `${formatDate(i.event_date)} – ${formatDate(i.end_date)}`
  return formatEventDate(i.event_date, null)
}

function ItemRow({
  item: i,
  canCorrect,
  canException,
  onCorrect,
  onException,
}: {
  item: Item
  canCorrect: boolean
  canException: boolean
  onCorrect: () => void
  onException: () => void
}) {
  const corrected = i.override_rate_role !== null || i.override_quantity !== null
  return (
    <li className="flex flex-col gap-2 px-3 py-2.5">
      <div className="flex flex-col gap-1 sm:flex-row sm:items-start sm:justify-between sm:gap-4">
        <div className="flex flex-col">
          <span className="text-sm text-muted-foreground tabular-nums">{dateText(i)}</span>
          <span className="font-medium">
            <Link to={`/ez/${i.event_id}`} className="underline-offset-4 hover:underline">
              {i.event_label ?? KIND_LABELS[i.event_kind as EventKind] ?? 'Einsatz'}
            </Link>
          </span>
          <span className="text-sm text-muted-foreground">
            {[KIND_LABELS[i.event_kind as EventKind], i.remuneration_kind, i.recorded_role ? ROLE_LABELS[i.recorded_role] : 'organisierende Person']
              .filter(Boolean)
              .join(' · ')}
          </span>
        </div>
        <div className="flex flex-col text-sm sm:items-end">
          <span>
            {POSITION_LABELS[i.position]} · {RATE_ROLE_LABELS[i.rate_role]}
            {i.override_rate_role && i.override_rate_role !== i.calc_rate_role && (
              <span className="text-muted-foreground"> (berechnet {RATE_ROLE_LABELS[i.calc_rate_role]})</span>
            )}
          </span>
          <span className="tabular-nums">
            {formatQuantity(i.quantity)}
            {i.override_quantity !== null && Number(i.override_quantity) !== Number(i.calc_quantity) && (
              <span className="text-muted-foreground"> (berechnet {formatQuantity(i.calc_quantity)})</span>
            )}{' '}
            × {formatMoney(i.rate)} = <span className="font-medium">{formatMoney(i.amount)}</span>
          </span>
        </div>
      </div>
      <HintBadges hints={i.hints} />
      {corrected && i.correction_reason && <p className="text-sm">Korrektur: {i.correction_reason}</p>}
      {i.exception_reason && <p className="text-sm">Ausnahme: {i.exception_reason}</p>}
      {(canCorrect || canException) && (
        <div className="flex flex-wrap gap-2">
          {canCorrect && (
            <Button variant="outline" size="sm" onClick={onCorrect}>
              <PencilIcon data-icon="inline-start" aria-hidden="true" />
              Korrigieren
            </Button>
          )}
          {canException && (
            <Button variant="outline" size="sm" onClick={onException}>
              Ausnahme begründen
            </Button>
          )}
        </div>
      )}
    </li>
  )
}

type Call = (name: string, args: Record<string, unknown>, success: string) => Promise<boolean>

/** Menge mit Komma oder Punkt; leer → null (berechnete Menge gilt). */
function parseQuantity(text: string): number | null {
  const t = text.trim().replace(',', '.')
  return t ? Number(t) : null
}

function CorrectDialog({
  item,
  pending,
  error,
  onClose,
  call,
  setError,
}: {
  item: Item
  pending: boolean
  error: string | null
  onClose: () => void
  call: Call
  setError: (text: string | null) => void
}) {
  const [role, setRole] = useState<RateRole | ''>(item.override_rate_role ?? '')
  const [quantity, setQuantity] = useState(item.override_quantity !== null ? String(item.override_quantity).replace('.', ',') : '')
  const [reason, setReason] = useState(item.correction_reason ?? '')
  const roles: RateRole[] = item.position === 'organization_day' ? ['none'] : ['trainer', 'helper']
  const hasOverride = item.override_rate_role !== null || item.override_quantity !== null

  return (
    <FormDialog
      title="Position korrigieren"
      description={`${POSITION_LABELS[item.position]} am ${formatDate(item.event_date)}: berechnet ${RATE_ROLE_LABELS[item.calc_rate_role]}, Menge ${formatQuantity(item.calc_quantity)}. Leere Felder übernehmen den berechneten Wert.`}
      submitLabel="Speichern"
      pendingLabel="Wird gespeichert …"
      pending={pending}
      error={error}
      onClose={onClose}
      extra={
        hasOverride && (
          <Button
            type="button"
            variant="ghost"
            disabled={pending}
            onClick={() => call('fi_correct_item', { p_item: item.id, p_rate_role: null, p_quantity: null, p_reason: null }, 'Die Korrektur wurde entfernt.')}
          >
            Korrektur entfernen
          </Button>
        )
      }
      onSubmit={() => {
        const q = parseQuantity(quantity)
        if (q !== null && Number.isNaN(q)) return setError(FI_MESSAGES.quantity)
        if (!role && q === null) return setError('Bitte Satzart oder Menge angeben oder „Korrektur entfernen“ wählen.')
        void call(
          'fi_correct_item',
          { p_item: item.id, p_rate_role: role || null, p_quantity: q, p_reason: reason },
          'Die Position wurde korrigiert.',
        )
      }}
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-rate-role">Satzart</Label>
        <select id="fi-rate-role" value={role} onChange={(e) => setRole(e.target.value as RateRole | '')} className={selectClassName}>
          <option value="">berechnet ({RATE_ROLE_LABELS[item.calc_rate_role]})</option>
          {roles.map((r) => (
            <option key={r} value={r}>
              {RATE_ROLE_LABELS[r]}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-quantity">Menge</Label>
        <Input
          id="fi-quantity"
          inputMode="decimal"
          value={quantity}
          placeholder={formatQuantity(item.calc_quantity)}
          onChange={(e) => setQuantity(e.target.value)}
          className="sm:w-32"
        />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-reason">Begründung</Label>
        <textarea
          id="fi-reason"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          maxLength={REASON_MAX}
          rows={3}
          className={textareaClassName}
        />
      </div>
    </FormDialog>
  )
}

function ReasonDialog({
  title,
  description,
  initial,
  required,
  submitLabel,
  pending,
  error,
  onClose,
  onSubmit,
}: {
  title: string
  description: string
  initial: string
  required: boolean
  submitLabel: string
  pending: boolean
  error: string | null
  onClose: () => void
  onSubmit: (reason: string) => void
}) {
  const [reason, setReason] = useState(initial)
  return (
    <FormDialog
      title={title}
      description={description}
      submitLabel={submitLabel}
      pendingLabel="Wird gespeichert …"
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={() => onSubmit(reason)}
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-reason">Begründung{required ? '' : ' (leer = entfernen)'}</Label>
        <textarea
          id="fi-reason"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          maxLength={REASON_MAX}
          rows={3}
          className={textareaClassName}
        />
      </div>
    </FormDialog>
  )
}

/** Abgabe erfassen (US-FI-12, R19): Datum; nach der Frist Rückfrage mit Pflichtbegründung. */
function SubmitDialog({
  settlementId,
  deadline,
  pending,
  error,
  onClose,
  call,
  setError,
}: {
  settlementId: string
  deadline: string | null
  pending: boolean
  error: string | null
  onClose: () => void
  call: Call
  setError: (text: string | null) => void
}) {
  const [date, setDate] = useState(todayIso())
  const [reason, setReason] = useState('')
  const late = !!deadline && !!date && date > deadline

  return (
    <FormDialog
      title="Abgabe erfassen"
      description={`Datum, an dem die unterschriebene Abrechnung in der Geschäftsstelle abgegeben wurde. Frist: ${deadline ? formatDate(deadline) : '–'}.`}
      submitLabel={late ? 'Trotzdem als abgegeben erfassen' : 'Speichern'}
      pendingLabel="Wird gespeichert …"
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={() => {
        if (late && !reason.trim()) return setError(FI_MESSAGES.reasonRequired)
        void call(
          'fi_record_submission',
          { p_id: settlementId, p_date: date, p_late_reason: late ? reason : null },
          'Die Abgabe wurde erfasst.',
        )
      }}
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-submitted-on">Abgegeben am</Label>
        <Input id="fi-submitted-on" type="date" value={date} max={todayIso()} onChange={(e) => setDate(e.target.value)} className="sm:w-44" />
      </div>
      {late && (
        <>
          <p role="alert" className="text-sm font-medium text-destructive">
            {FI_MESSAGES.lateReason}
          </p>
          <div className="flex flex-col gap-2">
            <Label htmlFor="fi-late-reason">Begründung</Label>
            <textarea
              id="fi-late-reason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              maxLength={REASON_MAX}
              rows={3}
              className={textareaClassName}
            />
          </div>
        </>
      )}
    </FormDialog>
  )
}
