import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { EZ_MESSAGES } from '@/features/ez/errors'
import { ezRpc } from '@/features/ez/shared/rpc'
import { FormError } from '@/features/gr/shared/ui'

const REASON_MAX = 500

// T031 (US-EZ-22, R22, R23): Absagen mit Pflichtfeld „Grund“ (1–500 Zeichen); nur ohne anwesende Personen.
export function AbsageDialog({ eventId, onClose, onDone }: { eventId: string; onClose: () => void; onDone: () => void }) {
  const [reason, setReason] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    const trimmed = reason.trim()
    if (!trimmed || trimmed.length > REASON_MAX) return setError(EZ_MESSAGES.cancelReason)
    setPending(true)
    const res = await ezRpc('ez_cancel_event', { p_id: eventId, p_reason: trimmed })
    setPending(false)
    if (res.error) return setError(res.error.text)
    onDone()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Einsatz absagen</DialogTitle>
          <DialogDescription>
            Der Einsatz bleibt mit dem Kennzeichen „abgesagt“ sichtbar und zählt nicht für die Abrechnung. Die Absage kann
            zurückgenommen werden.
          </DialogDescription>
        </DialogHeader>
        <form id="ez-cancel" onSubmit={onSubmit} noValidate className="flex flex-col gap-2">
          <Label htmlFor="ez-cancel-reason">Grund</Label>
          <textarea
            id="ez-cancel-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            maxLength={REASON_MAX}
            rows={3}
            required
            aria-invalid={error ? true : undefined}
            className="min-h-20 w-full rounded-lg border border-input bg-background px-2.5 py-2 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm"
          />
          <span className="text-xs text-muted-foreground tabular-nums">
            {reason.trim().length}/{REASON_MAX}
          </span>
        </form>
        <FormError text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="submit" form="ez-cancel" disabled={pending}>
            {pending ? 'Wird abgesagt …' : 'Absagen'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
