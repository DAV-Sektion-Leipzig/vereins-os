import { useMemo, useState, type FormEvent, type ReactNode } from 'react'
import { CircleAlertIcon, PencilIcon, PlusIcon, RotateCwIcon } from 'lucide-react'
import { useLoaderData, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAdAccess } from '@/features/ad/access'
import {
  DEFAULT_SLOTS,
  defaultAt,
  isNoRolePosition,
  POSITION_LABELS,
  POSITIONS,
  remunerationRates,
  saveDefault,
  saveKind,
  savePosition,
  slotLabel,
  type PositionCode,
  type RemunerationData,
  type RemunerationKind,
  type RemunerationPosition,
} from '@/features/ad/abrechnungsarten/data'
import { formatRate, ratesAt, type Rate } from '@/features/ad/saetze/data'
import type { EventKind, Span } from '@/features/ez/labels'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDate, todayIso } from '@/lib/format'
import { cn } from '@/lib/utils'

const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm'

type KindDialogState = { kind: RemunerationKind | null }
type PositionDialogState = { kind: RemunerationKind; position: RemunerationPosition | null }
type DefaultDialogState = { kind: EventKind; span: Span }

// T129 (spec.md AD v0.10, R51, R52): Abrechnungsarten nach Anhang 1 der Vergütungsordnung mit Positionen und
// Sätzen je Rolle; Vorbelegung der Abrechnungsart je Einsatzart mit „gültig ab“. Pflege nur Admin.
export function AbrechnungsartenPage() {
  const data = useLoaderData() as RemunerationData
  const { canEdit } = useAdAccess()
  const revalidator = useRevalidator()
  const [kindDialog, setKindDialog] = useState<KindDialogState | null>(null)
  const [positionDialog, setPositionDialog] = useState<PositionDialogState | null>(null)
  const [defaultDialog, setDefaultDialog] = useState<DefaultDialogState | null>(null)

  const current = useMemo(() => ratesAt(data.rates, todayIso()), [data.rates])
  const kindName = (id: string | null) => (id ? (data.kinds.find((k) => k.id === id)?.name ?? '–') : 'keine Vergütung')

  function saved(text: string) {
    toast.success(text)
    setKindDialog(null)
    setPositionDialog(null)
    setDefaultDialog(null)
    revalidator.revalidate()
  }

  if (data.failed) {
    return (
      <section className="flex flex-col items-start gap-3">
        <h1 className="text-xl font-semibold">Abrechnungsarten</h1>
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
      <div className="flex items-start justify-between gap-3">
        <div className="flex flex-col gap-1">
          <h1 className="text-xl font-semibold">Abrechnungsarten</h1>
          <p className="text-sm text-muted-foreground">
            Vergütung nach Anhang 1 der Vergütungsordnung. Die Beträge stehen unter „Sätze“; hier wird festgelegt, welcher
            Satz für welche Position gilt.
          </p>
        </div>
        {canEdit && (
          <Button onClick={() => setKindDialog({ kind: null })}>
            <PlusIcon data-icon="inline-start" aria-hidden="true" />
            Neu
          </Button>
        )}
      </div>

      {data.kinds.length === 0 ? (
        <p className="text-sm text-muted-foreground">Noch keine Abrechnungsarten.</p>
      ) : (
        <ul className="flex flex-col gap-3">
          {data.kinds.map((kind) => {
            const positions = data.positions
              .filter((p) => p.kind_id === kind.id)
              .sort((a, b) => POSITIONS.indexOf(a.position) - POSITIONS.indexOf(b.position))
            return (
              <li key={kind.id} className="flex flex-col gap-3 rounded-xl border p-4">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex flex-col">
                    <span className="font-medium">{kind.name}</span>
                    <span className="text-xs text-muted-foreground">
                      {kind.code} · {kind.source}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge
                      variant="outline"
                      className={cn(kind.is_active ? 'bg-status-active-bg text-status-active' : 'bg-status-none-bg text-status-none')}
                    >
                      {kind.is_active ? 'aktiv' : 'inaktiv'}
                    </Badge>
                    {canEdit && (
                      <Button variant="outline" size="sm" onClick={() => setKindDialog({ kind })}>
                        <PencilIcon data-icon="inline-start" aria-hidden="true" />
                        Bearbeiten
                      </Button>
                    )}
                  </div>
                </div>
                {positions.length === 0 ? (
                  <p className="text-sm text-muted-foreground">Noch keine Positionen.</p>
                ) : (
                  <dl className="flex flex-col divide-y text-sm">
                    {positions.map((p) => (
                      <div key={p.id} className="flex flex-col gap-1 py-2 sm:flex-row sm:items-center sm:justify-between">
                        <dt className="font-medium">{POSITION_LABELS[p.position]}</dt>
                        <dd className="flex flex-wrap items-center gap-x-4 gap-y-1 tabular-nums">
                          {isNoRolePosition(p.position) ? (
                            <RateRef label="ohne Rolle" rateKey={p.rate_key_none} current={current} />
                          ) : (
                            <>
                              <RateRef label="Trainer:in" rateKey={p.rate_key_trainer} current={current} />
                              <RateRef label="Helfer:in" rateKey={p.rate_key_helper} current={current} />
                            </>
                          )}
                          {canEdit && (
                            <Button variant="ghost" size="sm" onClick={() => setPositionDialog({ kind, position: p })}>
                              Ändern
                            </Button>
                          )}
                        </dd>
                      </div>
                    ))}
                  </dl>
                )}
                {canEdit && positions.length < POSITIONS.length && (
                  <Button variant="outline" size="sm" className="self-start" onClick={() => setPositionDialog({ kind, position: null })}>
                    <PlusIcon data-icon="inline-start" aria-hidden="true" />
                    Position hinzufügen
                  </Button>
                )}
              </li>
            )
          })}
        </ul>
      )}

      <section aria-labelledby="defaults-heading" className="flex flex-col gap-2">
        <h2 id="defaults-heading" className="font-medium">
          Vorbelegung je Einsatzart
        </h2>
        <p className="text-sm text-muted-foreground">
          Beim Anlegen eines Einsatzes ist diese Abrechnungsart vorausgewählt; am Einsatz kann eine andere oder „keine
          Vergütung“ gewählt werden.
        </p>
        <ul className="flex flex-col divide-y rounded-xl border">
          {DEFAULT_SLOTS.map(({ kind, span }) => {
            const now = defaultAt(data.defaults, kind, span)
            const history = data.defaults.filter((d) => d.event_kind === kind && d.span === span)
            return (
              <li key={`${kind}-${span}`} className="flex flex-col gap-1 px-4 py-2.5 text-sm sm:flex-row sm:items-center sm:justify-between">
                <span>{slotLabel(kind, span)}</span>
                <span className="flex flex-wrap items-center gap-x-3 gap-y-1">
                  <span className={now?.kind_id ? 'font-medium' : 'text-muted-foreground'}>
                    {now ? kindName(now.kind_id) : 'keine Vorbelegung'}
                  </span>
                  {now && <span className="text-muted-foreground tabular-nums">ab {formatDate(now.valid_from)}</span>}
                  {history.length > 1 && (
                    <details>
                      <summary className="cursor-pointer text-muted-foreground">Historie</summary>
                      <ul className="mt-1 tabular-nums">
                        {history.map((d) => (
                          <li key={d.id}>
                            ab {formatDate(d.valid_from)}: {kindName(d.kind_id)}
                          </li>
                        ))}
                      </ul>
                    </details>
                  )}
                  {canEdit && (
                    <Button variant="ghost" size="sm" onClick={() => setDefaultDialog({ kind, span })}>
                      Neuer Wert
                    </Button>
                  )}
                </span>
              </li>
            )
          })}
        </ul>
      </section>

      {kindDialog && (
        <KindDialog
          state={kindDialog}
          nextSort={Math.max(0, ...data.kinds.map((k) => k.sort_order)) + 10}
          onClose={() => setKindDialog(null)}
          onSaved={() => saved('Abrechnungsart gespeichert.')}
        />
      )}
      {positionDialog && (
        <PositionDialog
          state={positionDialog}
          taken={data.positions.filter((p) => p.kind_id === positionDialog.kind.id).map((p) => p.position)}
          rates={remunerationRates(data.rates)}
          onClose={() => setPositionDialog(null)}
          onSaved={() => saved('Position gespeichert.')}
        />
      )}
      {defaultDialog && (
        <DefaultDialog
          state={defaultDialog}
          kinds={data.kinds.filter((k) => k.is_active)}
          onClose={() => setDefaultDialog(null)}
          onSaved={() => saved('Vorbelegung gespeichert.')}
        />
      )}
    </section>
  )
}

function RateRef({ label, rateKey, current }: { label: string; rateKey: string | null; current: Map<string, Rate> }) {
  const rate = rateKey ? current.get(rateKey) : undefined
  return (
    <span>
      <span className="text-muted-foreground">{label}: </span>
      {rate ? formatRate(rate) : <span className="text-destructive">{rateKey ?? '–'} (kein gültiger Satz)</span>}
    </span>
  )
}

function FormError({ text }: { text: string | null }) {
  if (!text) return null
  return (
    <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
      <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
      {text}
    </p>
  )
}

function DialogShell({
  title,
  description,
  pending,
  error,
  onClose,
  onSubmit,
  children,
}: {
  title: string
  description?: string
  pending: boolean
  error: string | null
  onClose: () => void
  onSubmit: (event: FormEvent<HTMLFormElement>) => void
  children: ReactNode
}) {
  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
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
              {pending ? 'Speichern …' : 'Speichern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function KindDialog({
  state,
  nextSort,
  onClose,
  onSaved,
}: {
  state: KindDialogState
  nextSort: number
  onClose: () => void
  onSaved: () => void
}) {
  const existing = state.kind
  const [code, setCode] = useState(existing?.code ?? '')
  const [name, setName] = useState(existing?.name ?? '')
  const [source, setSource] = useState(existing?.source ?? 'Vergütungsordnung 2025, Anhang 1')
  const [active, setActive] = useState(existing?.is_active ?? true)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    if (!name.trim() || !source.trim() || (!existing && !/^[A-Z][A-Z_]{1,29}$/.test(code.trim().toUpperCase()))) {
      setError(MESSAGES.rateFieldRequired)
      return
    }
    setPending(true)
    const { error: saveError } = await saveKind(existing?.id ?? null, {
      code,
      name,
      source,
      is_active: active,
      sort_order: existing?.sort_order ?? nextSort,
    })
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved()
  }

  return (
    <DialogShell
      title={existing ? `Abrechnungsart: ${existing.name}` : 'Neue Abrechnungsart'}
      description={existing ? 'Inaktive Abrechnungsarten sind am Einsatz nicht mehr neu wählbar; vorhandene Einsätze behalten sie.' : undefined}
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={onSubmit}
    >
      {!existing && (
        <div className="flex flex-col gap-2">
          <Label htmlFor="kind-code">Code</Label>
          <Input id="kind-code" value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} placeholder="z. B. VOLUNTEER" />
          <p className="text-xs text-muted-foreground">Großbuchstaben und Unterstrich; später nicht änderbar.</p>
        </div>
      )}
      <div className="flex flex-col gap-2">
        <Label htmlFor="kind-name">Bezeichnung</Label>
        <Input id="kind-name" value={name} onChange={(e) => setName(e.target.value)} />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="kind-source">Quelle</Label>
        <Input id="kind-source" value={source} onChange={(e) => setSource(e.target.value)} />
      </div>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={active} onChange={(e) => setActive(e.target.checked)} className="size-4 accent-primary" />
        aktiv
      </label>
    </DialogShell>
  )
}

function RateSelect({ id, label, value, onChange, rates }: { id: string; label: string; value: string; onChange: (v: string) => void; rates: Rate[] }) {
  return (
    <div className="flex flex-col gap-2">
      <Label htmlFor={id}>{label}</Label>
      <select id={id} value={value} onChange={(e) => onChange(e.target.value)} className={selectClassName}>
        <option value="">bitte wählen</option>
        {rates.map((r) => (
          <option key={r.rate_key} value={r.rate_key}>
            {r.label} ({formatRate(r)})
          </option>
        ))}
      </select>
    </div>
  )
}

function PositionDialog({
  state,
  taken,
  rates,
  onClose,
  onSaved,
}: {
  state: PositionDialogState
  taken: PositionCode[]
  rates: Rate[]
  onClose: () => void
  onSaved: () => void
}) {
  const existing = state.position
  const free = POSITIONS.filter((p) => !taken.includes(p))
  const [position, setPosition] = useState<PositionCode>(existing?.position ?? free[0])
  const [trainer, setTrainer] = useState(existing?.rate_key_trainer ?? '')
  const [helper, setHelper] = useState(existing?.rate_key_helper ?? '')
  const [none, setNone] = useState(existing?.rate_key_none ?? '')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)
  const noRole = isNoRolePosition(position)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    if (noRole ? !none : !trainer || !helper) {
      setError(MESSAGES.rateFieldRequired)
      return
    }
    setPending(true)
    const { error: saveError } = await savePosition(existing, state.kind.id, position, { trainer, helper, none })
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved()
  }

  return (
    <DialogShell
      title={`${state.kind.name}: ${existing ? POSITION_LABELS[existing.position] : 'Position hinzufügen'}`}
      description="Der Betrag richtet sich nach dem Satz, der am Datum des Einsatzes gilt."
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={onSubmit}
    >
      {!existing && (
        <div className="flex flex-col gap-2">
          <Label htmlFor="position-code">Position</Label>
          <select id="position-code" value={position} onChange={(e) => setPosition(e.target.value as PositionCode)} className={selectClassName}>
            {free.map((p) => (
              <option key={p} value={p}>
                {POSITION_LABELS[p]}
              </option>
            ))}
          </select>
        </div>
      )}
      {noRole ? (
        <RateSelect id="position-none" label="Satz (ohne Rolle)" value={none} onChange={setNone} rates={rates} />
      ) : (
        <>
          <RateSelect id="position-trainer" label="Satz Trainer:in" value={trainer} onChange={setTrainer} rates={rates} />
          <RateSelect id="position-helper" label="Satz Helfer:in" value={helper} onChange={setHelper} rates={rates} />
        </>
      )}
    </DialogShell>
  )
}

function DefaultDialog({
  state,
  kinds,
  onClose,
  onSaved,
}: {
  state: DefaultDialogState
  kinds: RemunerationKind[]
  onClose: () => void
  onSaved: () => void
}) {
  const [kindId, setKindId] = useState('')
  const [validFrom, setValidFrom] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    if (!validFrom) {
      setError(MESSAGES.rateFieldRequired)
      return
    }
    setPending(true)
    const { error: saveError } = await saveDefault(state.kind, state.span, kindId || null, validFrom)
    setPending(false)
    if (saveError) setError(toMessage(saveError).text)
    else onSaved()
  }

  return (
    <DialogShell
      title={`Vorbelegung: ${slotLabel(state.kind, state.span)}`}
      description="Gilt für neu angelegte Einsätze, deren Datum ab diesem Tag liegt; vorhandene Einsätze behalten ihre Abrechnungsart."
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={onSubmit}
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="default-kind">Abrechnungsart</Label>
        <select id="default-kind" value={kindId} onChange={(e) => setKindId(e.target.value)} className={selectClassName}>
          <option value="">keine Vergütung</option>
          {kinds.map((k) => (
            <option key={k.id} value={k.id}>
              {k.name}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="default-from">gültig ab</Label>
        <Input id="default-from" type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} />
      </div>
    </DialogShell>
  )
}
