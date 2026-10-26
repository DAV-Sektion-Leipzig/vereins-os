import type { FormEvent, ReactNode } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { FormError } from '@/features/gr/shared/ui'

type Props = {
  title: string
  description?: ReactNode
  children: ReactNode
  submitLabel: string
  pendingLabel: string
  pending: boolean
  error: string | null
  destructive?: boolean
  /** Weitere Schaltfläche links neben „Abbrechen“, z. B. „Korrektur entfernen“. */
  extra?: ReactNode
  onSubmit: () => void
  onClose: () => void
}

// Dialog mit Eingaben (Korrektur, Begründung, Abgabe, Vertretung) für Finanzen (spec.md FI 6).
export function FormDialog({ title, description, children, submitLabel, pendingLabel, pending, error, destructive, extra, onSubmit, onClose }: Props) {
  function submit(e: FormEvent) {
    e.preventDefault()
    if (!pending) onSubmit()
  }
  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent showCloseButton={false} className="sm:max-w-lg">
        <form onSubmit={submit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>{title}</DialogTitle>
            {description && <DialogDescription>{description}</DialogDescription>}
          </DialogHeader>
          <div className="flex flex-col gap-4">{children}</div>
          <FormError text={error} />
          <DialogFooter className="flex-wrap">
            {extra}
            <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
              Abbrechen
            </Button>
            <Button type="submit" variant={destructive ? 'destructive' : 'default'} disabled={pending}>
              {pending ? pendingLabel : submitLabel}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
