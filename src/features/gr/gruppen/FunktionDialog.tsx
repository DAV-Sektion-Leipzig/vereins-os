import { useState, type FormEvent } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { GROUP_FUNCTIONS, type FunctionRow, type GroupFunction } from '@/features/gr/gruppen/detail'
import { choiceArgs } from '@/features/gr/personen/fields'
import { PersonWahl } from '@/features/gr/personen/PersonWahl'
import { grRpc } from '@/features/gr/shared/rpc'
import { FormError, selectClassName } from '@/features/gr/shared/ui'
import { MESSAGES } from '@/lib/errors'
import { formatDate, personName, todayIso } from '@/lib/format'

type AddResult = { property_id: string; status_hint: 'dormant' | 'left' | null; status_set: boolean }

const STATUS_HINTS: Record<'dormant' | 'left', string> = {
  dormant: 'Die Person ist im Ehrenamtsmanagement ruhend.',
  left: 'Die Person ist im Ehrenamtsmanagement ausgeschieden.',
}

// T043 (US-GR-13, R28, R29): Gruppenleitung, Trainer:in oder Helfer:in eintragen. Personen ohne Ehrenamtsstatus
// werden „aktiv“; bei „ruhend“ oder „ausgeschieden“ bleibt der Status, es erscheint ein Hinweis.
export function FunktionHinzufuegenDialog({ groupId, onClose, onDone }: { groupId: string; onClose: () => void; onDone: () => void }) {
  const [fn, setFn] = useState<GroupFunction>('Trainer:in')
  const [validFrom, setValidFrom] = useState(todayIso())
  const [validTo, setValidTo] = useState('')

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Funktion hinzufügen</DialogTitle>
          <DialogDescription>Die Funktion erscheint im Ehrenamtsmanagement nur lesend.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-3 sm:grid-cols-3">
          <div className="flex flex-col gap-2">
            <Label htmlFor="gr-fn">Funktion</Label>
            <select id="gr-fn" value={fn} onChange={(e) => setFn(e.target.value as GroupFunction)} className={selectClassName}>
              {GROUP_FUNCTIONS.map((f) => (
                <option key={f} value={f}>
                  {f}
                </option>
              ))}
            </select>
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="gr-fn-from">seit</Label>
            <Input id="gr-fn-from" type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="gr-fn-to">bis (optional)</Label>
            <Input id="gr-fn-to" type="date" value={validTo} onChange={(e) => setValidTo(e.target.value)} />
          </div>
        </div>
        <PersonWahl
          idPrefix="gr-fn-person"
          fields={['first_name', 'last_name', 'phone_mobile', 'email']}
          required={['first_name', 'last_name']}
          submitLabel="Funktion eintragen"
          onChoose={async (choice) => {
            if (!validFrom) return MESSAGES.grConsentDateRequired
            if (validTo && validTo < validFrom) return MESSAGES.validRange
            const result = await grRpc<AddResult>('gr_add_group_function', {
              p_group: groupId,
              p_function: fn,
              p_valid_from: validFrom,
              p_valid_to: validTo || null,
              ...choiceArgs(choice),
            })
            if (result.error !== null) return result.error
            if (result.data.status_hint) toast.info(STATUS_HINTS[result.data.status_hint])
            else if (result.data.status_set) toast.success('Die Person ist im Ehrenamtsmanagement jetzt aktiv.')
            onDone()
            return null
          }}
        />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose}>
            Schließen
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

// T043: Funktion beenden bzw. „bis“ ändern; der Ehrenamtsstatus bleibt (R29)
export function FunktionBeendenDialog({ row, onClose, onDone }: { row: FunctionRow; onClose: () => void; onDone: () => void }) {
  const [validTo, setValidTo] = useState(row.valid_to ?? todayIso())
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setPending(true)
    const result = await grRpc('gr_end_group_function', { p_property: row.id, p_valid_to: validTo || null })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    onDone()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{row.valid_to ? '„Bis“ ändern' : 'Funktion beenden'}</DialogTitle>
          <DialogDescription>
            {personName(row)}: {row.function} seit {formatDate(row.valid_from)}
          </DialogDescription>
        </DialogHeader>
        <form id="gr-fn-end" onSubmit={onSubmit} noValidate className="flex flex-col gap-2">
          <Label htmlFor="gr-fn-end-date">bis</Label>
          <Input id="gr-fn-end-date" type="date" value={validTo} onChange={(e) => setValidTo(e.target.value)} className="sm:w-44" />
        </form>
        <FormError text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="submit" form="gr-fn-end" disabled={pending}>
            {pending ? 'Speichern …' : 'Speichern'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
