import { CircleAlertIcon, RotateCwIcon, TriangleAlertIcon } from 'lucide-react'
import { Link, useRevalidator } from 'react-router-dom'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { MESSAGES } from '@/lib/errors'
import { cn } from '@/lib/utils'
import { OUTBOX_LABELS, STATE_LABELS, type ConnectionState, type OutboxState, type StatusHint } from '@/features/sc/data'

// Gemeinsame Bausteine der Seite „Schnittstellen“.

export function LoadFailed({ title }: { title: string }) {
  const revalidator = useRevalidator()
  return (
    <section className="flex flex-col items-start gap-3">
      <h1 className="text-xl font-semibold">{title}</h1>
      <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
        <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
        {MESSAGES.unexpected}
      </p>
      <Button variant="outline" onClick={() => revalidator.revalidate()} disabled={revalidator.state === 'loading'}>
        <RotateCwIcon data-icon="inline-start" aria-hidden="true" />
        {revalidator.state === 'loading' ? 'Wird geladen …' : 'Erneut laden'}
      </Button>
    </section>
  )
}

export function ErrorText({ text }: { text: string | null }) {
  if (!text) return null
  return (
    <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
      <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
      {text}
    </p>
  )
}

export function StateBadge({ state }: { state: ConnectionState }) {
  const variant = state === 'active' ? 'default' : state === 'disabled' ? 'outline' : 'destructive'
  return <Badge variant={variant}>{STATE_LABELS[state]}</Badge>
}

export function OutboxBadge({ state }: { state: OutboxState }) {
  const variant = state === 'sent' ? 'secondary' : state === 'failed' ? 'destructive' : 'outline'
  return <Badge variant={variant}>{OUTBOX_LABELS[state]}</Badge>
}

/** Hinweise aus sc_status() (US-SC-13); auf der Startseite mit Link zu den Schnittstellen. */
export function StatusHints({ hints, withLink = false, className }: { hints: StatusHint[]; withLink?: boolean; className?: string }) {
  if (hints.length === 0) return null
  return (
    <div role="status" className={cn('flex flex-col gap-2 rounded-xl border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm', className)}>
      <ul className="flex flex-col gap-1">
        {hints.map((h) => (
          <li key={`${h.kind}-${h.message}`} className="flex items-start gap-2">
            <TriangleAlertIcon aria-hidden="true" className="mt-0.5 size-4 shrink-0 text-destructive" />
            <span>
              {h.message}
              {withLink && h.kind === 'failed' && (
                <>
                  {' '}
                  <Link to="/schnittstellen/postausgang?zustand=failed" className="underline underline-offset-4">
                    Zum Postausgang
                  </Link>
                </>
              )}
            </span>
          </li>
        ))}
      </ul>
      {withLink && (
        <Link to="/schnittstellen" className="self-start font-medium underline underline-offset-4">
          Zu den Schnittstellen
        </Link>
      )}
    </div>
  )
}

/** Filter als einfache Auswahl (natives select, mobil gut bedienbar). */
export function FilterSelect({
  id,
  label,
  value,
  options,
  onChange,
}: {
  id: string
  label: string
  value: string
  options: { value: string; label: string }[]
  onChange: (value: string) => void
}) {
  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={id} className="text-xs text-muted-foreground">
        {label}
      </label>
      <select
        id={id}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="h-8 rounded-lg border bg-background px-2 text-sm outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
      >
        <option value="">alle</option>
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </div>
  )
}

export function FilterDate({ id, label, value, onChange }: { id: string; label: string; value: string; onChange: (value: string) => void }) {
  return (
    <div className="flex flex-col gap-1">
      <label htmlFor={id} className="text-xs text-muted-foreground">
        {label}
      </label>
      <input
        id={id}
        type="date"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="h-8 rounded-lg border bg-background px-2 text-sm outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
      />
    </div>
  )
}
