// Dialoge der Budget-Sicht: Hinweis (US-DS-11, R17), Umschichtung beantragen (US-DS-12, R15), Umschlüsselung
// vorschlagen (US-DS-14, R16), Umschlüsseln durch die Budgetpflege (US-FI-27). Die Datenbank prüft Rechte und Regeln.
import { useState, type ReactNode } from 'react'
import { useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { dsRpc, DS_MESSAGES } from '@/features/ds/errors'
import type { Booking, OverviewItem } from '@/features/ds/budget/data'
import { euro, euroCents, textareaClassName } from '@/features/ds/budget/ui'
import { FormError, selectClassName } from '@/features/gr/shared/ui'
import { formatDate } from '@/lib/format'
import { EURO_INPUT_HINT, parseEuro } from '@/lib/money'

type ShellProps = {
  title: string
  description?: ReactNode
  children: ReactNode
  submitLabel: string
  pending: boolean
  error: string | null
  onSubmit: () => void
  onClose: () => void
}

function DialogShell({ title, description, children, submitLabel, pending, error, onSubmit, onClose }: ShellProps) {
  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-lg">
        <form
          className="flex flex-col gap-4"
          onSubmit={(e) => {
            e.preventDefault()
            onSubmit()
          }}
        >
          <DialogHeader>
            <DialogTitle>{title}</DialogTitle>
            {description && <DialogDescription>{description}</DialogDescription>}
          </DialogHeader>
          {children}
          <FormError text={error} />
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
              Abbrechen
            </Button>
            <Button type="submit" disabled={pending}>
              {pending ? 'Wird gespeichert …' : submitLabel}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function useSubmit(onDone: () => void) {
  const revalidator = useRevalidator()
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  async function submit(fn: string, args: Record<string, unknown>, success: string) {
    setPending(true)
    setError(null)
    const res = await dsRpc(fn, args)
    setPending(false)
    if (res.error) return setError(res.error.text)
    toast.success(success)
    onDone()
    revalidator.revalidate()
  }
  return { pending, error, setError, submit }
}

// ---------------------------------------------------------------------------------------------------------------

export function NoteDialog({ item, onClose }: { item: OverviewItem; onClose: () => void }) {
  const [text, setText] = useState(item.note ?? '')
  const { pending, error, setError, submit } = useSubmit(onClose)
  return (
    <DialogShell
      title="Hinweis eintragen"
      description={`${item.group_name} · ${item.name}. Den Hinweis sehen alle mit Zugriff auf das Dashboard.`}
      submitLabel={text.trim() === '' && item.note ? 'Hinweis entfernen' : 'Speichern'}
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={() => {
        if (text.trim().length > 500) return setError(DS_MESSAGES.noteTooLong)
        submit('fi_budget_note_save', { p_item: item.item_id, p_text: text }, 'Hinweis gespeichert.')
      }}
    >
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="note-text">Hinweis</Label>
        <textarea
          id="note-text"
          className={textareaClassName}
          value={text}
          maxLength={600}
          onChange={(e) => setText(e.target.value)}
          placeholder="z. B. „Neue Seile im Herbst bestellt“"
        />
        <span className="text-xs text-muted-foreground">{text.trim().length} / 500 Zeichen · leer lassen entfernt den Hinweis</span>
      </div>
    </DialogShell>
  )
}

// ---------------------------------------------------------------------------------------------------------------

type ReallocProps = {
  items: OverviewItem[]
  from?: OverviewItem
  /** Budgetpflege: sofort bestätigt (spec 2.3, p_direct). */
  direct?: boolean
  onClose: () => void
}

export function ReallocDialog({ items, from, direct = false, onClose }: ReallocProps) {
  const editable = items.filter((i) => i.can_edit && i.kind === 'expense')
  const [fromId, setFromId] = useState(from?.item_id ?? editable[0]?.item_id ?? '')
  const source = items.find((i) => i.item_id === fromId)
  const targets = items.filter((i) => source && i.group_id === source.group_id && i.kind === source.kind && i.item_id !== fromId)
  const [toId, setToId] = useState('')
  const [amount, setAmount] = useState('')
  const [reason, setReason] = useState('')
  const { pending, error, setError, submit } = useSubmit(onClose)
  const target = targets.find((t) => t.item_id === toId)

  return (
    <DialogShell
      title={direct ? 'Umschichten' : 'Umschichtung beantragen'}
      description={
        direct
          ? 'Gilt sofort. Die Summe des Gesamtbudgets bleibt gleich.'
          : 'Die Budgetpflege bestätigt die Umschichtung. Die Summe des Gesamtbudgets bleibt gleich.'
      }
      submitLabel={direct ? 'Umschichten' : 'Beantragen'}
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={() => {
        // Freitext, kein DATEV-Format: „12.50“ = 12,50 €, Tausenderpunkt ungültig (W-02)
        const value = parseEuro(amount)
        if (!source || !target) return setError(DS_MESSAGES.reallocGroup)
        if (value === null || value <= 0) return setError(EURO_INPUT_HINT)
        if (reason.trim() === '') return setError(DS_MESSAGES.reasonRequired)
        submit(
          'fi_budget_realloc_request',
          { p_from: source.item_id, p_to: target.item_id, p_amount: value, p_reason: reason, p_direct: direct },
          direct ? 'Umgeschichtet.' : 'Umschichtung beantragt.',
        )
      }}
    >
      <div className="grid gap-3 sm:grid-cols-2">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="realloc-from">von</Label>
          <select
            id="realloc-from"
            className={selectClassName + ' sm:max-w-none'}
            value={fromId}
            onChange={(e) => {
              setFromId(e.target.value)
              setToId('')
            }}
          >
            {editable.map((i) => (
              <option key={i.item_id} value={i.item_id}>
                {i.group_name} · {i.name} ({euro(i.plan_current)})
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="realloc-to">nach</Label>
          <select
            id="realloc-to"
            className={selectClassName + ' sm:max-w-none'}
            value={toId}
            onChange={(e) => setToId(e.target.value)}
          >
            <option value="">Bitte wählen</option>
            {targets.map((i) => (
              <option key={i.item_id} value={i.item_id}>
                {i.name} ({euro(i.plan_current)})
              </option>
            ))}
          </select>
        </div>
      </div>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="realloc-amount">Betrag in €</Label>
        <Input id="realloc-amount" inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} className="sm:max-w-40" />
        {source && <span className="text-xs text-muted-foreground">höchstens {euroCents(source.plan_current)} (aktueller Plan)</span>}
      </div>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="realloc-reason">Grund</Label>
        <textarea id="realloc-reason" className={textareaClassName} value={reason} maxLength={500} onChange={(e) => setReason(e.target.value)} />
      </div>
    </DialogShell>
  )
}

// ---------------------------------------------------------------------------------------------------------------

type RekeyProps = {
  booking: Booking
  item: OverviewItem
  items: OverviewItem[]
  /** Budgetpflege schlüsselt direkt um; sonst Vorschlag an die Budgetpflege. */
  maintain: boolean
  onClose: () => void
}

export function RekeyDialog({ booking, item, items, maintain, onClose }: RekeyProps) {
  const targets = items.filter((i) => i.item_id !== item.item_id)
  const [toId, setToId] = useState('')
  const [scope, setScope] = useState<'booking' | 'account'>('booking')
  const [reason, setReason] = useState('')
  const { pending, error, setError, submit } = useSubmit(onClose)

  return (
    <DialogShell
      title={maintain ? 'Umschlüsseln' : 'Umschlüsselung vorschlagen'}
      description={
        <>
          {formatDate(booking.booking_date)} · Konto {booking.account} · {booking.booking_text ?? '–'} · {euroCents(booking.amount)}
          {!maintain && <span className="mt-1 block">Die Budgetpflege entscheidet über den Vorschlag.</span>}
        </>
      }
      submitLabel={maintain ? 'Umschlüsseln' : 'Vorschlagen'}
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={() => {
        if (!toId) return setError('Bitte einen Budgetposten wählen.')
        if (reason.trim() === '') return setError(DS_MESSAGES.reasonRequired)
        if (maintain) {
          submit('fi_budget_rekey', { p_booking: booking.booking_id, p_item: toId, p_scope: scope, p_reason: reason }, 'Umgeschlüsselt.')
        } else {
          submit('fi_budget_proposal_create', { p_booking: booking.booking_id, p_to: toId, p_reason: reason }, 'Vorschlag gesendet.')
        }
      }}
    >
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="rekey-to">neuer Budgetposten</Label>
        <select id="rekey-to" className={selectClassName + ' sm:max-w-none'} value={toId} onChange={(e) => setToId(e.target.value)}>
          <option value="">Bitte wählen</option>
          {targets.map((i) => (
            <option key={i.item_id} value={i.item_id}>
              {i.group_name} · {i.name}
              {i.kind === 'income' ? ' (Einnahme)' : ''}
            </option>
          ))}
        </select>
      </div>
      {maintain && (
        <fieldset className="flex flex-col gap-1.5">
          <legend className="mb-1 text-sm font-medium">Umfang</legend>
          <label className="flex items-center gap-2 text-sm">
            <input type="radio" name="rekey-scope" checked={scope === 'booking'} onChange={() => setScope('booking')} />
            nur diese Buchung
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input type="radio" name="rekey-scope" checked={scope === 'account'} onChange={() => setScope('account')} />
            alle Buchungen auf Konto {booking.account}
          </label>
        </fieldset>
      )}
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="rekey-reason">Grund</Label>
        <textarea id="rekey-reason" className={textareaClassName} value={reason} maxLength={500} onChange={(e) => setReason(e.target.value)} />
      </div>
    </DialogShell>
  )
}

// ---------------------------------------------------------------------------------------------------------------

type DecideProps = {
  title: string
  description: ReactNode
  fn: string
  args: (reason: string) => Record<string, unknown>
  /** Begründung Pflicht (Ablehnen). */
  reasonRequired: boolean
  submitLabel: string
  success: string
  onClose: () => void
}

/** Bestätigen, annehmen oder ablehnen mit (optionaler) Begründung. */
export function DecideDialog({ title, description, fn, args, reasonRequired, submitLabel, success, onClose }: DecideProps) {
  const [reason, setReason] = useState('')
  const { pending, error, setError, submit } = useSubmit(onClose)
  return (
    <DialogShell
      title={title}
      description={description}
      submitLabel={submitLabel}
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={() => {
        if (reasonRequired && reason.trim() === '') return setError(DS_MESSAGES.reasonRequired)
        submit(fn, args(reason), success)
      }}
    >
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="decide-reason">{reasonRequired ? 'Grund' : 'Bemerkung (optional)'}</Label>
        <textarea id="decide-reason" className={textareaClassName} value={reason} maxLength={500} onChange={(e) => setReason(e.target.value)} />
      </div>
    </DialogShell>
  )
}
