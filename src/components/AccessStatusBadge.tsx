import { CircleCheckIcon, CircleDashedIcon, LockIcon, MailIcon, type LucideIcon } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import type { AccessStatus } from '@/lib/rights'
import { cn } from '@/lib/utils'

// Status eines Zugangs (glossar.md): Farbe nach DESIGN.md, immer mit Text und Symbol.
const STATUS: Record<AccessStatus, { label: string; icon: LucideIcon; className: string }> = {
  none: { label: 'kein Zugang', icon: CircleDashedIcon, className: 'bg-status-none-bg text-status-none' },
  invited: { label: 'eingeladen', icon: MailIcon, className: 'bg-status-invited-bg text-status-invited' },
  active: { label: 'aktiv', icon: CircleCheckIcon, className: 'bg-status-active-bg text-status-active' },
  locked: { label: 'gesperrt', icon: LockIcon, className: 'bg-status-locked-bg text-status-locked' },
}

export function AccessStatusBadge({ status, className }: { status: AccessStatus; className?: string }) {
  const { label, icon: Icon, className: statusClassName } = STATUS[status]
  return (
    <Badge className={cn(statusClassName, className)}>
      <Icon data-icon="inline-start" aria-hidden="true" />
      {label}
    </Badge>
  )
}
