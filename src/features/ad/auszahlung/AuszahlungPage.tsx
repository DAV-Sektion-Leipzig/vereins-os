import { useState, type FormEvent } from 'react'
import { CircleAlertIcon, EyeIcon, EyeOffIcon, PlusIcon, RotateCwIcon } from 'lucide-react'
import { useLoaderData, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAdAccess } from '@/features/ad/access'
import {
  deadlineLabel,
  formatIban,
  saveCollectionStart,
  saveDeadline,
  savePayoutSettings,
  setSemiannual,
  type PayoutAdminData,
  type PayoutSettings,
} from '@/features/ad/auszahlung/data'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDate, todayIso } from '@/lib/format'

// T129 (spec.md AD v0.10, R53, R54): Abgabefristen der halbjährlichen Abrechnung, Kennzeichen am Referat und
// Angaben der Sektion für Auszahlliste und Überweisungsdatei; v0.11 (R57, R58; T133): Gläubiger-ID, Sachkonto der
// Gruppenbeiträge und Stichtag des ersten Buchungslaufs. Pflege nur Admin.
export function AuszahlungPage() {
  const data = useLoaderData() as PayoutAdminData
  const { canEdit } = useAdAccess()
  const revalidator = useRevalidator()
  const [deadlineHalf, setDeadlineHalf] = useState<1 | 2 | null>(null)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [startOpen, setStartOpen] = useState(false)
  const [showIban, setShowIban] = useState(false)
  const [togglePending, setTogglePending] = useState<string | null>(null)

  const today = todayIso()
  const current = data.settings.find((s) => s.valid_from <= today) ?? null

  function saved(text: string) {
    toast.success(text)
    setDeadlineHalf(null)
    setSettingsOpen(false)
    setStartOpen(false)
    revalidator.revalidate()
  }

  async function toggle(referatId: string, value: boolean) {
    setTogglePending(referatId)
    const { error } = await setSemiannual(referatId, value)
    setTogglePending(null)
    if (error) toast.error(toMessage(error).text)
    else revalidator.revalidate()
  }

  if (data.failed) {
    return (
      <section className="flex flex-col items-start gap-3">
        <h1 className="text-xl font-semibold">Auszahlung</h1>
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {MESSAGES.unexpected}
        </p>
        <Button variant="outline" onClick={() => revalidator.revalidate()} disabled={revalidator.state === 'loading'}>
          <RotateCwIcon data-icon="inline-start" aria-hidden="true" />
          Erneut laden
        </Button>
      </section>
    )
  }

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold">Auszahlung</h1>
        <p className="text-sm text-muted-foreground">Einstellungen für die halbjährliche Abrechnung und die Auszahlung in Finanzen.</p>
      </div>

      <section aria-labelledby="deadlines-heading" className="flex flex-col gap-2">
        <h2 id="deadlines-heading" className="font-medium">
          Abgabefristen
        </h2>
        <ul className="flex max-w-2xl flex-col divide-y rounded-xl border">
          {([1, 2] as const).map((half) => {
            const rows = data.deadlines.filter((d) => d.half === half)
            const now = rows.find((d) => d.valid_from <= today)
            return (
              <li key={half} className="flex flex-col gap-1 px-4 py-2.5 text-sm sm:flex-row sm:items-center sm:justify-between">
                <span>{half}. Halbjahr</span>
                <span className="flex flex-wrap items-center gap-x-3 gap-y-1 tabular-nums">
                  <span className="font-medium">{now ? deadlineLabel(now) : 'keine Frist'}</span>
                  {now && <span className="text-muted-foreground">ab {formatDate(now.valid_from)}</span>}
                  {rows.length > 1 && (
                    <details>
                      <summary className="cursor-pointer text-muted-foreground">Historie</summary>
                      <ul className="mt-1">
                        {rows.map((d) => (
                          <li key={d.id}>
                            ab {formatDate(d.valid_from)}: {deadlineLabel(d)}
                          </li>
                        ))}
                      </ul>
                    </details>
                  )}
                  {canEdit && (
                    <Button variant="ghost" size="sm" onClick={() => setDeadlineHalf(half)}>
                      Neuer Wert
                    </Button>
                  )}
                </span>
              </li>
            )
          })}
        </ul>
      </section>

      <section aria-labelledby="semiannual-heading" className="flex flex-col gap-2">
        <h2 id="semiannual-heading" className="font-medium">
          Halbjährliche Abrechnung je Referat
        </h2>
        <p className="text-sm text-muted-foreground">
          Für diese Referate berechnet Finanzen die Abrechnung je Halbjahr mit Abrechnungsdokument und Abgabefrist.
        </p>
        <ul className="flex max-w-2xl flex-col divide-y rounded-xl border">
          {data.referate
            .filter((r) => r.is_active || r.semiannual_settlement)
            .map((r) => (
              <li key={r.id} className="flex items-center justify-between gap-3 px-4 py-2.5 text-sm">
                <label htmlFor={`semi-${r.id}`}>{r.name}</label>
                <input
                  id={`semi-${r.id}`}
                  type="checkbox"
                  checked={r.semiannual_settlement}
                  disabled={!canEdit || togglePending === r.id}
                  onChange={(e) => toggle(r.id, e.target.checked)}
                  className="size-4 cursor-pointer accent-primary disabled:cursor-not-allowed disabled:opacity-50"
                />
              </li>
            ))}
        </ul>
      </section>

      <section aria-labelledby="settings-heading" className="flex flex-col gap-2">
        <div className="flex items-center justify-between gap-3">
          <h2 id="settings-heading" className="font-medium">
            Angaben der Sektion
          </h2>
          {canEdit && (
            <Button variant="outline" size="sm" onClick={() => setSettingsOpen(true)}>
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              Neue Angaben
            </Button>
          )}
        </div>
        {!current ? (
          <p className="text-sm text-muted-foreground">
            Noch keine Angaben der Sektion. Ohne sie kann Finanzen keine Auszahlungsrunde freigeben.
          </p>
        ) : (
          <dl className="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-2 rounded-xl border p-4 text-sm sm:grid-cols-[max-content_1fr]">
            <dt className="text-muted-foreground">Name (Auftraggeber)</dt>
            <dd>{current.debtor_name}</dd>
            <dt className="text-muted-foreground">IBAN</dt>
            <dd className="flex items-center gap-2 tabular-nums">
              {formatIban(current.iban, showIban)}
              <Button variant="ghost" size="icon-xs" onClick={() => setShowIban((v) => !v)} aria-label={showIban ? 'IBAN verbergen' : 'IBAN anzeigen'}>
                {showIban ? <EyeOffIcon aria-hidden="true" /> : <EyeIcon aria-hidden="true" />}
              </Button>
            </dd>
            <dt className="text-muted-foreground">BIC</dt>
            <dd className="tabular-nums">{current.bic}</dd>
            <dt className="text-muted-foreground">Sachkonto Übungsleitervergütung</dt>
            <dd className="tabular-nums">{current.ledger_account}</dd>
            <dt className="text-muted-foreground">Gläubiger-ID</dt>
            <dd className="tabular-nums">{current.creditor_id ?? '–'}</dd>
            <dt className="text-muted-foreground">Sachkonto Gruppenbeiträge</dt>
            <dd className="tabular-nums">{current.ledger_account_collection ?? '–'}</dd>
            <dt className="text-muted-foreground">gültig ab</dt>
            <dd className="tabular-nums">{formatDate(current.valid_from)}</dd>
          </dl>
        )}
      </section>

      <section aria-labelledby="collection-heading" className="flex flex-col gap-2">
        <div className="flex items-center justify-between gap-3">
          <h2 id="collection-heading" className="font-medium">
            Buchungslauf Verträge
          </h2>
          {canEdit && (
            <Button variant="outline" size="sm" onClick={() => setStartOpen(true)}>
              {data.collectionStart ? 'Stichtag ändern' : 'Stichtag festlegen'}
            </Button>
          )}
        </div>
        <p className="max-w-2xl text-sm text-muted-foreground">
          Stichtag des ersten Buchungslaufs im Vereins OS: {data.collectionStart ? formatMonth(data.collectionStart) : 'nicht festgelegt'}.
          Verträge mit Beginn davor gelten als bereits eingezogen (Folgelastschrift). Ohne Stichtag und Gläubiger-ID ist
          kein Buchungslauf möglich.
        </p>
      </section>

      {deadlineHalf && (
        <DeadlineDialog half={deadlineHalf} onClose={() => setDeadlineHalf(null)} onSaved={() => saved('Abgabefrist gespeichert.')} />
      )}
      {settingsOpen && (
        <SettingsDialog
          initial={current}
          onClose={() => setSettingsOpen(false)}
          onSaved={() => saved('Angaben der Sektion gespeichert.')}
        />
      )}
      {startOpen && (
        <StartDialog
          initial={data.collectionStart}
          onClose={() => setStartOpen(false)}
          onSaved={() => saved('Stichtag gespeichert.')}
        />
      )}
    </section>
  )
}

function ErrorText({ text }: { text: string | null }) {
  if (!text) return null
  return (
    <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
      <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
      {text}
    </p>
  )
}

function DeadlineDialog({ half, onClose, onSaved }: { half: 1 | 2; onClose: () => void; onSaved: () => void }) {
  const [day, setDay] = useState('')
  const [month, setMonth] = useState('')
  const [validFrom, setValidFrom] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    if (!day || !month || !validFrom) {
      setError(MESSAGES.rateFieldRequired)
      return
    }
    setPending(true)
    const { error: saveError } = await saveDeadline(half, Number(day), Number(month), validFrom)
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>Abgabefrist {half}. Halbjahr</DialogTitle>
            <DialogDescription>Die Frist liegt im Jahr des Halbjahres; danach erlischt der Anspruch.</DialogDescription>
          </DialogHeader>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-2">
              <Label htmlFor="deadline-day">Tag</Label>
              <Input id="deadline-day" type="number" min={1} max={31} value={day} onChange={(e) => setDay(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="deadline-month">Monat</Label>
              <Input id="deadline-month" type="number" min={1} max={12} value={month} onChange={(e) => setMonth(e.target.value)} />
            </div>
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="deadline-from">gültig ab</Label>
            <Input id="deadline-from" type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} />
          </div>
          <ErrorText text={error} />
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
              Abbrechen
            </Button>
            <Button type="submit" disabled={pending}>
              {pending ? 'Speichern …' : 'Speichern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function SettingsDialog({ initial, onClose, onSaved }: { initial: PayoutSettings | null; onClose: () => void; onSaved: () => void }) {
  // Vorbelegt mit den aktuellen Angaben; gespeichert wird immer eine neue Zeile mit „gültig ab“
  const [debtorName, setDebtorName] = useState(initial?.debtor_name ?? '')
  const [iban, setIban] = useState(initial?.iban ?? '')
  const [bic, setBic] = useState(initial?.bic ?? '')
  const [ledger, setLedger] = useState(initial?.ledger_account ?? '')
  const [creditorId, setCreditorId] = useState(initial?.creditor_id ?? '')
  const [ledgerCollection, setLedgerCollection] = useState(initial?.ledger_account_collection ?? '')
  const [validFrom, setValidFrom] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    if (!debtorName.trim() || !iban.trim() || !bic.trim() || !ledger.trim() || !validFrom) {
      setError(MESSAGES.rateFieldRequired)
      return
    }
    setPending(true)
    const { error: saveError } = await savePayoutSettings({
      debtor_name: debtorName,
      iban,
      bic,
      ledger_account: ledger,
      valid_from: validFrom,
      creditor_id: creditorId,
      ledger_account_collection: ledgerCollection,
    })
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>Neue Angaben der Sektion</DialogTitle>
            <DialogDescription>
              Gelten für Auszahlungsrunden mit Ausführungsdatum ab „gültig ab“. Frühere Angaben bleiben erhalten.
            </DialogDescription>
          </DialogHeader>
          <div className="flex flex-col gap-2">
            <Label htmlFor="payout-name">Name (Auftraggeber, höchstens 70 Zeichen)</Label>
            <Input id="payout-name" maxLength={70} value={debtorName} onChange={(e) => setDebtorName(e.target.value)} />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="payout-iban">IBAN</Label>
            <Input id="payout-iban" autoComplete="off" value={iban} onChange={(e) => setIban(e.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-2">
              <Label htmlFor="payout-bic">BIC</Label>
              <Input id="payout-bic" autoComplete="off" value={bic} onChange={(e) => setBic(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="payout-ledger">Sachkonto Übungsleitervergütung</Label>
              <Input id="payout-ledger" maxLength={20} value={ledger} onChange={(e) => setLedger(e.target.value)} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-2">
              <Label htmlFor="payout-creditor">Gläubiger-ID (für den Einzug)</Label>
              <Input id="payout-creditor" autoComplete="off" maxLength={18} value={creditorId} onChange={(e) => setCreditorId(e.target.value)} />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="payout-ledger-collection">Sachkonto Gruppenbeiträge</Label>
              <Input
                id="payout-ledger-collection"
                maxLength={20}
                value={ledgerCollection}
                onChange={(e) => setLedgerCollection(e.target.value)}
              />
            </div>
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="payout-from">gültig ab</Label>
            <Input id="payout-from" type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} />
          </div>
          <ErrorText text={error} />
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
              Abbrechen
            </Button>
            <Button type="submit" disabled={pending}>
              {pending ? 'Speichern …' : 'Speichern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function formatMonth(day: string) {
  const [y, m] = day.split('-')
  return `${m}/${y}`
}

function StartDialog({ initial, onClose, onSaved }: { initial: string | null; onClose: () => void; onSaved: () => void }) {
  const [month, setMonth] = useState(initial ? initial.slice(0, 7) : todayIso().slice(0, 7))
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    if (!/^\d{4}-\d{2}$/.test(month)) {
      setError(MESSAGES.rateFieldRequired)
      return
    }
    setPending(true)
    const { error: saveError } = await saveCollectionStart(month, initial !== null)
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>Stichtag des ersten Buchungslaufs</DialogTitle>
            <DialogDescription>
              Monat des ersten Buchungslaufs im Vereins OS. Verträge mit Beginn vor diesem Monat werden als Folgelastschrift
              eingezogen; frühere Monate sind nicht wählbar.
            </DialogDescription>
          </DialogHeader>
          <div className="flex flex-col gap-2">
            <Label htmlFor="collection-start">Monat</Label>
            <Input id="collection-start" type="month" value={month} onChange={(e) => setMonth(e.target.value)} className="sm:w-48" />
          </div>
          <ErrorText text={error} />
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
              Abbrechen
            </Button>
            <Button type="submit" disabled={pending}>
              {pending ? 'Speichern …' : 'Speichern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
