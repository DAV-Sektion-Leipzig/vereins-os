import { CircleAlertIcon, CircleCheckIcon, ClockIcon, type LucideIcon } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

// Ablaufstatus nach ea_expiry_status (R9 EA): Farbe nach DESIGN.md, immer mit Text und Symbol; „none“ zeigt „–“.
export type ExpiryStatus = 'expired' | 'expiring' | 'valid' | 'none'

const STATUS: Record<Exclude<ExpiryStatus, 'none'>, { label: string; icon: LucideIcon; className: string }> = {
  expired: { label: 'abgelaufen', icon: CircleAlertIcon, className: 'bg-destructive/10 text-destructive' },
  expiring: { label: 'läuft in ≤ 3 Monaten ab', icon: ClockIcon, className: 'bg-status-locked-bg text-status-locked' },
  valid: { label: 'gültig', icon: CircleCheckIcon, className: 'bg-status-active-bg text-status-active' },
}

export function AblaufBadge({ status, className }: { status: ExpiryStatus; className?: string }) {
  if (status === 'none') return <span className="text-muted-foreground">–</span>
  const { label, icon: Icon, className: statusClassName } = STATUS[status]
  return (
    <Badge className={cn(statusClassName, className)}>
      <Icon data-icon="inline-start" aria-hidden="true" />
      {label}
    </Badge>
  )
}
