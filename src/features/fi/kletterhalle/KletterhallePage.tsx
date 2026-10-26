import { useState } from 'react'
import { useLoaderData, useNavigate, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { ResponsiveTable } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Table, TableBody, TableCell, TableFooter, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { weekdayShort } from '@/features/ez/dates'
import { climbingHref, type ClimbingCheck, type ClimbingResult } from '@/features/fi/kletterhalle/data'
import { fiRpc } from '@/features/fi/rpc'
import { textareaClassName } from '@/features/fi/shared/ui'
import { FormError, LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime } from '@/lib/format'

// FT15 (US-FI-17): Kontrollliste je Training (ohne Namen) mit Summen ohne/mit Probetrainings; Anzahl laut Rechnung,
// Rechnungsnummer und Bemerkung erfassen, Abweichung anzeigen, Abgleich speichern; gespeicherte Abgleiche.
export function KletterhallePage() {
  const { filter, locations, rows, checks, failed } = useLoaderData() as ClimbingResult
  const navigate = useNavigate()
  const revalidator = useRevalidator()
  const [from, setFrom] = useState(filter.from)
  const [to, setTo] = useState(filter.to)
  const [invoiced, setInvoiced] = useState('')
  const [invoiceNumber, setInvoiceNumber] = useState('')
  const [remark, setRemark] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const set = (patch: Partial<typeof filter>) => navigate(climbingHref({ ...filter, ...patch }), { replace: true })
  const without = rows.reduce((s, r) => s + r.participants_present, 0)
  const trials = rows.reduce((s, r) => s + r.trial_count, 0)
  const withTrials = without + trials
  const invoicedNumber = invoiced.trim() === '' ? null : Number(invoiced)
  const valid = invoicedNumber !== null && Number.isInteger(invoicedNumber) && invoicedNumber >= 0

  async function save() {
    if (!valid) return setError('Bitte eine ganze Zahl ab 0 eingeben.')
    setPending(true)
    setError(null)
    const res = await fiRpc('fi_save_climbing_check', {
      p_location: filter.location,
      p_from: filter.from,
      p_to: filter.to,
      p_invoiced: invoicedNumber,
      p_invoice_number: invoiceNumber.trim() || null,
      p_remark: remark.trim() || null,
    })
    setPending(false)
    if (res.error) return setError(res.error.text)
    toast.success('Der Abgleich wurde gespeichert.')
    setInvoiced('')
    setInvoiceNumber('')
    setRemark('')
    revalidator.revalidate()
  }

  return (
    <section className="flex flex-col gap-6">
      <h1 className="text-xl font-semibold">Punktekonto Kletterhalle</h1>

      <form
        onSubmit={(e) => {
          e.preventDefault()
          set({ from, to })
        }}
        className="flex flex-col gap-4 sm:flex-row sm:flex-wrap sm:items-end"
      >
        <div className="flex flex-col gap-2">
          <Label htmlFor="fi-kh-location">Ort</Label>
          <select id="fi-kh-location" value={filter.location} onChange={(e) => set({ location: e.target.value })} className={selectClassName}>
            {locations.length === 0 && <option value="">Kein Ort mit Punktekonto</option>}
            {locations.map((l) => (
              <option key={l.id} value={l.id}>
                {l.is_active ? l.name : `${l.name} (nicht mehr aktiv)`}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="fi-kh-from">von</Label>
          <Input id="fi-kh-from" type="date" value={from} onChange={(e) => setFrom(e.target.value)} onBlur={() => set({ from, to })} className="sm:w-44" />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="fi-kh-to">bis</Label>
          <Input id="fi-kh-to" type="date" value={to} onChange={(e) => setTo(e.target.value)} onBlur={() => set({ from, to })} className="sm:w-44" />
        </div>
      </form>

      {failed ? (
        <LoadFailed />
      ) : rows.length === 0 ? (
        <p className="text-sm text-muted-foreground">Keine Trainings im Zeitraum.</p>
      ) : (
        <div className="overflow-hidden rounded-xl border">
          <Table>
            <caption className="sr-only">Trainings mit anwesenden Teilnehmer:innen und Probetrainings</caption>
            <TableHeader>
              <TableRow className="bg-muted hover:bg-muted">
                <TableHead className="pl-4">Datum</TableHead>
                <TableHead className="whitespace-normal">Gruppe</TableHead>
                <TableHead className="text-right whitespace-normal">Teilnehmer:innen</TableHead>
                <TableHead className="pr-4 text-right whitespace-normal">Probetraining</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.event_id} className="hover:bg-transparent">
                  <TableCell className="pl-4 tabular-nums">
                    {weekdayShort(r.start_date)} {formatDate(r.start_date)}
                  </TableCell>
                  <TableCell className="whitespace-normal">{r.group_name}</TableCell>
                  <TableCell className="text-right tabular-nums">{r.participants_present}</TableCell>
                  <TableCell className="pr-4 text-right tabular-nums">{r.trial_count}</TableCell>
                </TableRow>
              ))}
            </TableBody>
            <TableFooter>
              <TableRow className="font-medium hover:bg-transparent">
                <TableCell className="pl-4" colSpan={2}>
                  Summe ({rows.length} {rows.length === 1 ? 'Training' : 'Trainings'})
                </TableCell>
                <TableCell className="text-right tabular-nums">{without}</TableCell>
                <TableCell className="pr-4 text-right tabular-nums">{trials}</TableCell>
              </TableRow>
            </TableFooter>
          </Table>
        </div>
      )}

      {!failed && filter.location && (
        <section aria-labelledby="fi-kh-check" className="flex flex-col gap-4 rounded-xl border p-4">
          <h2 id="fi-kh-check" className="text-lg font-semibold">
            Abgleich mit der Rechnung
          </h2>
          <dl className="grid grid-cols-[max-content_1fr] gap-x-6 gap-y-1 text-sm">
            <dt className="text-muted-foreground">ohne Probetrainings</dt>
            <dd className="tabular-nums">{without}</dd>
            <dt className="text-muted-foreground">mit Probetrainings</dt>
            <dd className="tabular-nums">{withTrials}</dd>
          </dl>
          <form
            onSubmit={(e) => {
              e.preventDefault()
              void save()
            }}
            className="flex flex-col gap-4"
          >
            <div className="flex flex-col gap-4 sm:flex-row sm:flex-wrap">
              <div className="flex flex-col gap-2">
                <Label htmlFor="fi-kh-invoiced">Anzahl laut Rechnung</Label>
                <Input id="fi-kh-invoiced" inputMode="numeric" value={invoiced} onChange={(e) => setInvoiced(e.target.value)} className="sm:w-32" />
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="fi-kh-number">Rechnungsnummer (optional)</Label>
                <Input id="fi-kh-number" value={invoiceNumber} maxLength={50} onChange={(e) => setInvoiceNumber(e.target.value)} className="sm:w-56" />
              </div>
            </div>
            {valid && (
              <p className="text-sm" role="status">
                Abweichung: {deviation(invoicedNumber - without)} gegenüber ohne Probetrainings, {deviation(invoicedNumber - withTrials)} gegenüber mit
                Probetrainings.
              </p>
            )}
            <div className="flex flex-col gap-2">
              <Label htmlFor="fi-kh-remark">Bemerkung (optional)</Label>
              <textarea id="fi-kh-remark" value={remark} maxLength={500} rows={2} onChange={(e) => setRemark(e.target.value)} className={textareaClassName} />
            </div>
            <FormError text={error} />
            <Button type="submit" disabled={pending} className="self-start">
              {pending ? 'Wird gespeichert …' : 'Abgleich speichern'}
            </Button>
          </form>
        </section>
      )}

      {checks.length > 0 && (
        <section aria-labelledby="fi-kh-saved" className="flex flex-col gap-2">
          <h2 id="fi-kh-saved" className="text-lg font-semibold">
            Gespeicherte Abgleiche
          </h2>
          <ResponsiveTable
            rows={checks}
            rowKey={(c) => c.id}
            columns={[
              { key: 'period', header: 'Zeitraum', cell: (c: ClimbingCheck) => `${formatDate(c.period_from)} – ${formatDate(c.period_to)}`, className: 'tabular-nums' },
              { key: 'counted', header: 'ohne / mit Probetrainings', cell: (c: ClimbingCheck) => `${c.counted_without_trials} / ${c.counted_with_trials}`, className: 'tabular-nums' },
              { key: 'invoiced', header: 'laut Rechnung', cell: (c: ClimbingCheck) => c.invoiced, className: 'tabular-nums' },
              { key: 'number', header: 'Rechnung', cell: (c: ClimbingCheck) => c.invoice_number ?? '–' },
              { key: 'remark', header: 'Bemerkung', cell: (c: ClimbingCheck) => c.remark ?? '' },
              { key: 'by', header: 'Gespeichert', cell: (c: ClimbingCheck) => `${formatDateTime(c.created_at)}${c.created_by_name ? ` von ${c.created_by_name}` : ''}`, className: 'text-sm' },
            ]}
            card={(c) => (
              <div className="flex flex-col gap-1 text-sm">
                <span className="font-medium tabular-nums">
                  {formatDate(c.period_from)} – {formatDate(c.period_to)}
                </span>
                <span>
                  gezählt {c.counted_without_trials} / {c.counted_with_trials}, laut Rechnung {c.invoiced}
                  {c.invoice_number ? ` (${c.invoice_number})` : ''}
                </span>
                {c.remark && <span className="text-muted-foreground">{c.remark}</span>}
              </div>
            )}
            empty=""
            caption="Gespeicherte Abgleiche"
          />
        </section>
      )}
    </section>
  )
}

function deviation(n: number): string {
  return n === 0 ? 'keine' : n > 0 ? `+${n}` : String(n)
}
