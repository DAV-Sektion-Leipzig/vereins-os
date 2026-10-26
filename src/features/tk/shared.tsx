import { LockIcon } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { STATUS_LABELS } from '@/features/tk/labels'
import type { PlanStatus } from '@/features/tk/types'
import { cn } from '@/lib/utils'

// Gemeinsame Bausteine der Planungshilfe (spec.md TK 6).

const STATUS_STYLES: Record<PlanStatus, string> = {
  draft: 'border-border text-foreground',
  submitted: 'border-primary/40 text-primary',
  query: 'bg-destructive/10 text-destructive border-transparent',
  approved: 'bg-primary/10 text-primary border-transparent',
  published: 'bg-primary text-primary-foreground border-transparent',
  done: 'bg-secondary text-secondary-foreground border-transparent',
  closed: 'bg-muted text-muted-foreground border-transparent',
  cancelled: 'bg-muted text-muted-foreground border-transparent line-through',
}

export function StatusBadge({ status }: { status: PlanStatus }) {
  return (
    <Badge variant="outline" className={cn(STATUS_STYLES[status])}>
      {(status === 'closed' || status === 'done') && <LockIcon data-icon="inline-start" aria-hidden="true" />}
      {STATUS_LABELS[status]}
    </Badge>
  )
}

export const textareaClassName =
  'min-h-24 w-full rounded-lg border border-input bg-background px-2.5 py-2 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:opacity-60 sm:text-sm'
