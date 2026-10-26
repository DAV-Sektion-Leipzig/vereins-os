import { CircleAlertIcon, LockIcon } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { hintLabel, STATUS_LABELS, type SettlementStatus } from '@/features/fi/labels'
import { cn } from '@/lib/utils'

// Gemeinsame Bausteine der Finanzen (spec.md FI 6): Zustand als Abzeichen, Hinweise als Symbol mit Text.

const STATUS_STYLES: Record<SettlementStatus, string> = {
  draft: 'border-border text-foreground',
  confirmed: 'border-primary/40 text-primary',
  closed: 'bg-primary/10 text-primary border-transparent',
  submitted: 'bg-primary text-primary-foreground border-transparent',
  expired: 'bg-muted text-muted-foreground border-transparent',
  paid: 'bg-secondary text-secondary-foreground border-transparent',
}

export function StatusBadge({ status }: { status: SettlementStatus }) {
  return (
    <Badge variant="outline" className={cn(STATUS_STYLES[status])}>
      {(status === 'closed' || status === 'submitted' || status === 'paid') && <LockIcon data-icon="inline-start" aria-hidden="true" />}
      {STATUS_LABELS[status]}
    </Badge>
  )
}

/** Hinweis ohne Sperre der Berechnung (R4–R14); Text immer sichtbar, nicht nur das Symbol. */
export function HintBadges({ hints, year }: { hints: string[]; year?: number }) {
  if (hints.length === 0) return null
  return (
    <ul className="flex flex-wrap gap-1">
      {hints.map((h) => (
        <li key={h}>
          <Badge className="h-auto min-h-5 justify-start bg-destructive/10 text-left whitespace-normal text-destructive">
            <CircleAlertIcon data-icon="inline-start" aria-hidden="true" />
            {hintLabel(h, year)}
          </Badge>
        </li>
      ))}
    </ul>
  )
}

export const textareaClassName =
  'min-h-20 w-full rounded-lg border border-input bg-background px-2.5 py-2 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm'
