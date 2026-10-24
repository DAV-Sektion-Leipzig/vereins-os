import type { ReactNode } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { FormError } from '@/features/gr/shared/ui'

type Props = {
  title: string
  children?: ReactNode
  confirmLabel: string
  pendingLabel: string
  pending: boolean
  error: string | null
  destructive?: boolean
  onConfirm: () => void
  onClose: () => void
}

// Rückfrage vor Löschen, Absage zurücknehmen und Wieder-aktiv-Eintragen (R15, R24, R31).
export function ConfirmDialog({ title, children, confirmLabel, pendingLabel, pending, error, destructive, onConfirm, onClose }: Props) {
  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent showCloseButton={false} className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          {children && <DialogDescription>{children}</DialogDescription>}
        </DialogHeader>
        <FormError text={error} />
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button variant={destructive ? 'destructive' : 'default'} onClick={onConfirm} disabled={pending}>
            {pending ? pendingLabel : confirmLabel}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
