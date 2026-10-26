import { LockIcon } from 'lucide-react'
import { Badge } from '@/components/ui/badge'

/** Kennzeichen „abgerechnet“ mit Schloss an Einsatz und Person (spec.md EZ 6, v0.6; R34). */
export function SettledBadge() {
  return (
    <Badge variant="secondary">
      <LockIcon data-icon="inline-start" aria-hidden="true" />
      abgerechnet
    </Badge>
  )
}
