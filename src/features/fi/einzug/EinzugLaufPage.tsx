import { useState } from 'react'
import { FileDownIcon, PlusIcon, RefreshCwIcon, SendIcon, Trash2Icon } from 'lucide-react'
import { Link, useLoaderData, useNavigate, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { runTitle, type CollectionDetail, type CollectionLine, type DetailResult } from '@/features/fi/einzug/data'
import { FI_MESSAGES } from '@/features/fi/errors'
import { downloadCollectionFiles, reportCollectionDownload } from '@/features/fi/export/collection'
import { formatMoney } from '@/features/fi/labels'
import { fiRpc } from '@/features/fi/rpc'
import { FormDialog } from '@/features/fi/shared/FormDialog'
import { HintBadges, textareaClassName } from '@/features/fi/shared/ui'
import { FormError, LoadFailed } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime } from '@/lib/format'
import { parseEuro } from '@/lib/money'
import { cn } from '@/lib/utils'

type Dialog = { kind: 'release' | 'discard' | 'refetch' } | { kind: 'extra'; line: CollectionLine } | null

// FT23 (US-FI-18 bis -21; R34–R47): Entwurf mit Lastschriften je Gruppe (abwählen, Zusatzbetrag), Fälligkeitstag,
// Aktualisieren, Verwerfen, Freigeben mit Download von Lastschriftdatei und Einzugsliste; freigegeben: erneut abrufen.
export function EinzugLaufPage() {
  const { detail, failed } = useLoaderData() as DetailResult
  if (failed || !detail) {
    return (
      <section className="flex flex-col gap-4">
        <h1 className="text-xl font-semibold">Buchungslauf</h1>
        <LoadFailed />
        <Button variant="outline" asChild className="self-start">
          <Link to="/fi/einzug">Zur Liste</Link>
        </Button>
      </section>
    )
  }
  return <Run key={detail.run.id} detail={detail} />
}

function groupLines(lines: CollectionLine[]) {
  const map = new Map<string, CollectionLine[]>()
  for (const l of lines) map.set(l.group_label, [...(map.get(l.group_label) ?? []), l])
  return [...map.entries()].sort(([a], [b]) => a.localeCompare(b, 'de-DE', { numeric: true }))
}

function Run({ detail }: { detail: CollectionDetail }) {
  const { run, lines, settings_ok: settingsOk, min_due_date: minDueDate } = detail
  const navigate = useNavigate()
  const revalidator = useRevalidator()
  const [dialog, setDialog] = useState<Dialog>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [dueDate, setDueDate] = useState(run.due_date)
  const draft = run.status === 'draft'
  const included = lines.filter((l) => l.included)
  const excluded = lines.filter((l) => l.excluded_reason)
  const total = included.reduce((s, l) => s + Number(l.amount), 0)

  function close() {
    setDialog(null)
    setError(null)
  }

  async function call(name: string, args: Record<string, unknown>, success?: string): Promise<boolean> {
    setPending(true)
    setError(null)
    const res = await fiRpc(name, args)
    setPending(false)
    if (res.error) {
      setError(res.error.text)
      return false
    }
    if (success) toast.success(success)
    revalidator.revalidate()
    return true
  }

  async function release() {
    setPending(true)
    setError(null)
    const res = await fiRpc('fi_release_collection_run', { p_run: run.id })
    if (res.error) {
      setPending(false)
      return setError(res.error.text)
    }
    const files = await downloadCollectionFiles(run.id)
    setPending(false)
    close()
    revalidator.revalidate()
    if (files.error) return toast.error(`Der Buchungslauf ist freigegeben. ${files.error} Bitte die Dateien erneut abrufen.`)
    reportCollectionDownload(files.bankChanged)
  }

  async function refetch() {
    setPending(true)
    const files = await downloadCollectionFiles(run.id)
    setPending(false)
    if (files.error) return setError(files.error)
    close()
    reportCollectionDownload(files.bankChanged)
  }

  async function discard() {
    if (await call('fi_discard_collection_run', { p_run: run.id }, 'Der Buchungslauf wurde verworfen.')) navigate('/fi/einzug')
  }

  return (
    <section className="flex flex-col gap-6">
      <header className="flex flex-col gap-3">
        <div className="flex flex-col gap-1">
          <Link to="/fi/einzug" className="text-sm text-muted-foreground underline-offset-4 hover:underline">
            Buchungsläufe Verträge
          </Link>
          <div className="flex flex-wrap items-baseline justify-between gap-3">
            <h1 className="text-xl font-semibold">{runTitle(run)}</h1>
            <span className="text-xl font-semibold tabular-nums">{formatMoney(draft ? total : run.total)}</span>
          </div>
          <div>
            <Badge variant={draft ? 'outline' : 'default'}>{draft ? 'Entwurf' : 'freigegeben'}</Badge>
          </div>
        </div>
        {draft && !settingsOk && <p className="rounded-lg border bg-muted/50 p-3 text-sm">{FI_MESSAGES.collectionSettingsMissing}</p>}
        <div className="flex flex-wrap gap-2">
          {draft ? (
            <>
              <Button onClick={() => setDialog({ kind: 'release' })} disabled={included.length === 0 || pending || !settingsOk}>
                <SendIcon data-icon="inline-start" aria-hidden="true" />
                Freigeben
              </Button>
              <Button variant="outline" onClick={() => call('fi_refresh_collection_run', { p_run: run.id }, 'Der Buchungslauf wurde aktualisiert.')} disabled={pending}>
                <RefreshCwIcon data-icon="inline-start" aria-hidden="true" />
                Aktualisieren
              </Button>
              <Button variant="outline" onClick={() => setDialog({ kind: 'discard' })} disabled={pending}>
                <Trash2Icon data-icon="inline-start" aria-hidden="true" />
                Verwerfen
              </Button>
            </>
          ) : (
            <Button variant="outline" onClick={() => setDialog({ kind: 'refetch' })}>
              <FileDownIcon data-icon="inline-start" aria-hidden="true" />
              PDF und XML erneut abrufen
            </Button>
          )}
        </div>
        {!dialog && <FormError text={error} />}
      </header>

      {draft ? (
        <form
          onSubmit={(e) => {
            e.preventDefault()
            void call('fi_update_collection_run', { p_run: run.id, p_due_date: dueDate }, 'Der Fälligkeitstag wurde gespeichert.')
          }}
          className="flex flex-wrap items-end gap-2"
        >
          <div className="flex flex-col gap-2">
            <Label htmlFor="fi-due-date">Fälligkeitstag</Label>
            <Input id="fi-due-date" type="date" value={dueDate} min={minDueDate} onChange={(e) => setDueDate(e.target.value)} className="sm:w-44" />
          </div>
          <Button type="submit" variant="outline" disabled={pending || dueDate === run.due_date}>
            Speichern
          </Button>
        </form>
      ) : (
        <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
          {(
            [
              ['Fälligkeitstag', formatDate(run.due_date)],
              ['Freigegeben', run.released_at ? `${formatDateTime(run.released_at)}${run.released_by_name ? ` von ${run.released_by_name}` : ''}` : '–'],
              ['Lastschriften', String(run.line_count ?? lines.length)],
              ['Nachrichten-ID', run.msg_id ?? '–'],
            ] as [string, string][]
          ).map(([label, value]) => (
            <div key={label} className="contents">
              <dt className="text-muted-foreground">{label}</dt>
              <dd className="mb-2 break-all sm:mb-0">{value}</dd>
            </div>
          ))}
        </dl>
      )}

      <section aria-labelledby="fi-collection-lines" className="flex flex-col gap-4">
        <div className="flex items-baseline justify-between gap-3">
          <h2 id="fi-collection-lines" className="text-lg font-semibold">
            Lastschriften
          </h2>
          <span className="text-sm text-muted-foreground tabular-nums">
            {draft ? included.length : (run.line_count ?? lines.length)} · {formatMoney(draft ? total : run.total)}
          </span>
        </div>
        {lines.length === 0 && <p className="text-sm text-muted-foreground">Keine Verträge zum Einziehen.</p>}
        {groupLines(lines.filter((l) => !l.excluded_reason)).map(([group, list]) => {
          const sum = list.filter((l) => l.included).reduce((s, l) => s + Number(l.amount), 0)
          return (
            <div key={group} className="flex flex-col gap-2">
              <div className="flex items-baseline justify-between gap-3">
                <h3 className="font-medium">{group}</h3>
                <span className="text-sm text-muted-foreground tabular-nums">Summe {formatMoney(sum)}</span>
              </div>
              <ul className="flex flex-col divide-y rounded-xl border">
                {list.map((l) => (
                  <LineRow
                    key={l.id}
                    line={l}
                    draft={draft}
                    pending={pending}
                    onToggle={(on) => call('fi_set_collection_included', { p_collection: l.id, p_included: on })}
                    onExtra={() => setDialog({ kind: 'extra', line: l })}
                  />
                ))}
              </ul>
            </div>
          )
        })}
        {draft && excluded.length > 0 && (
          <div className="flex flex-col gap-2">
            <h3 className="font-medium">Ausgeschlossen</h3>
            <ul className="flex flex-col divide-y rounded-xl border">
              {excluded.map((l) => (
                <li key={l.id} className="flex flex-col gap-1 px-3 py-2.5 text-sm">
                  <span className="font-medium">
                    {l.participant_name} · {l.group_label}
                  </span>
                  <span className="text-destructive">
                    Mandat noch nicht unterschrieben (unterschrieben am {formatDate(l.mandate_signed_on)})
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </section>

      {dialog?.kind === 'release' && (
        <ConfirmDialog
          title="Buchungslauf freigeben?"
          confirmLabel="Freigeben"
          pendingLabel="Wird freigegeben …"
          pending={pending}
          error={error}
          onConfirm={release}
          onClose={close}
        >
          Buchungslauf {runTitle(run)} mit {included.length} Lastschriften über {formatMoney(total)} freigeben? Fälligkeit{' '}
          {formatDate(run.due_date)}.
        </ConfirmDialog>
      )}
      {dialog?.kind === 'discard' && (
        <ConfirmDialog
          title="Buchungslauf verwerfen?"
          confirmLabel="Verwerfen"
          pendingLabel="Wird verworfen …"
          pending={pending}
          error={error}
          destructive
          onConfirm={discard}
          onClose={close}
        >
          Die Verträge werden für diesen Monat wieder frei. Die Nummer des Laufs wird nicht erneut vergeben.
        </ConfirmDialog>
      )}
      {dialog?.kind === 'refetch' && (
        <ConfirmDialog
          title="Dateien erneut abrufen?"
          confirmLabel="Herunterladen"
          pendingLabel="Wird erzeugt …"
          pending={pending}
          error={error}
          onConfirm={refetch}
          onClose={close}
        >
          {FI_MESSAGES.collectionReleased}
        </ConfirmDialog>
      )}
      {dialog?.kind === 'extra' && (
        <ExtraDialog
          line={dialog.line}
          pending={pending}
          error={error}
          onClose={close}
          onSave={async (amount, text, reason) => {
            if (await call('fi_set_collection_extra', { p_collection: dialog.line.id, p_amount: amount, p_text: text, p_reason: reason }, amount === null ? 'Der Zusatzbetrag wurde entfernt.' : 'Der Zusatzbetrag wurde gespeichert.')) close()
          }}
        />
      )}
    </section>
  )
}

function LineRow({
  line: l,
  draft,
  pending,
  onToggle,
  onExtra,
}: {
  line: CollectionLine
  draft: boolean
  pending: boolean
  onToggle: (on: boolean) => void
  onExtra: () => void
}) {
  const id = `fi-col-${l.id}`
  return (
    <li className={cn('flex flex-col gap-2 px-3 py-2.5 sm:flex-row sm:items-start sm:justify-between', !l.included && 'text-muted-foreground')}>
      <label htmlFor={id} className={cn('flex min-h-11 flex-1 items-start gap-3', draft && 'cursor-pointer')}>
        {draft && (
          <input
            id={id}
            type="checkbox"
            checked={l.included}
            disabled={pending}
            onChange={(e) => onToggle(e.target.checked)}
            className="mt-0.5 size-5 shrink-0 accent-primary"
          />
        )}
        <span className="flex flex-col gap-0.5 text-sm">
          <span className="font-medium text-foreground">{l.participant_name}</span>
          <span>
            {l.holder_name ?? '–'} · Mandat {l.mandate_reference} · IBAN •••• {l.iban_last4 ?? '–'} ·{' '}
            {l.sequence === 'FRST' ? 'Erstlastschrift' : 'Folgelastschrift'}
          </span>
          {l.extra_amount !== null && (
            <span>
              Zusatz {formatMoney(l.extra_amount)} „{l.extra_text}“ – {l.extra_reason}
            </span>
          )}
          {l.remittance && <span className="text-muted-foreground">{l.remittance}</span>}
          {l.bank_changed_since_last && <HintBadges hints={['Bankverbindung seit dem letzten Einzug geändert']} />}
        </span>
      </label>
      <div className="flex items-center gap-2 sm:flex-col sm:items-end">
        <span className={cn('tabular-nums', l.included && 'font-medium text-foreground')}>{formatMoney(l.amount)}</span>
        {draft && l.included && (
          <Button variant="ghost" size="sm" onClick={onExtra} disabled={pending}>
            <PlusIcon data-icon="inline-start" aria-hidden="true" />
            {l.extra_amount !== null ? 'Zusatz ändern' : 'Zusatzbetrag'}
          </Button>
        )}
      </div>
    </li>
  )
}

/** R47: Zusatzbetrag für eine Nachzahlung mit Text im Verwendungszweck und Begründung. */
function ExtraDialog({
  line,
  pending,
  error,
  onClose,
  onSave,
}: {
  line: CollectionLine
  pending: boolean
  error: string | null
  onClose: () => void
  onSave: (amount: number | null, text: string | null, reason: string | null) => void
}) {
  const [amount, setAmount] = useState(line.extra_amount !== null ? String(line.extra_amount).replace('.', ',') : '')
  const [text, setText] = useState(line.extra_text ?? '')
  const [reason, setReason] = useState(line.extra_reason ?? '')
  const [localError, setLocalError] = useState<string | null>(null)
  return (
    <FormDialog
      title={`Zusatzbetrag: ${line.participant_name}`}
      description={`Monatsbetrag ${formatMoney(line.monthly_amount)}. Der Text wird an den Verwendungszweck angehängt, z. B. „und rückwirkend bis Mai 2026“.`}
      submitLabel="Speichern"
      pendingLabel="Wird gespeichert …"
      pending={pending}
      error={localError ?? error}
      onClose={onClose}
      extra={
        line.extra_amount !== null && (
          <Button type="button" variant="ghost" disabled={pending} onClick={() => onSave(null, null, null)}>
            Zusatz entfernen
          </Button>
        )
      }
      onSubmit={() => {
        // Zusatzbetrag nur positiv (fi_set_collection_extra: p_amount > 0); „12.50“ = 12,50 €, Tausenderpunkt ungültig
        const value = parseEuro(amount)
        if (value === null) return setLocalError(FI_MESSAGES.amountInvalid)
        setLocalError(null)
        onSave(value, text, reason)
      }}
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-extra-amount">Zusatzbetrag (€)</Label>
        <Input id="fi-extra-amount" inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} className="sm:w-32" />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-extra-text">Text im Verwendungszweck (höchstens 60 Zeichen)</Label>
        <Input id="fi-extra-text" maxLength={60} value={text} onChange={(e) => setText(e.target.value)} />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-extra-reason">Begründung</Label>
        <textarea id="fi-extra-reason" value={reason} maxLength={500} rows={3} onChange={(e) => setReason(e.target.value)} className={textareaClassName} />
      </div>
    </FormDialog>
  )
}
