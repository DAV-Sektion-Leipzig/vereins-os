import { useState, type FormEvent } from 'react'
import { CircleAlertIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import type { PropertiesData } from '@/features/ad/personen/data'
import { buildLeavePlan, type LeavePlan } from '@/features/ea/aktive/ausscheiden'
import { AusscheidenSchritt } from '@/features/ea/aktive/AusscheidenSchritt'
import {
  changeVolunteerStatus,
  leaveVolunteer,
  loadPersonReferate,
  VOLUNTEER_STATUS_LABELS,
  type VolunteerStatus,
} from '@/features/ea/aktive/data'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDate } from '@/lib/format'

type Props = {
  personId: string
  personName: string
  current: VolunteerStatus
  properties: PropertiesData | null
  writable: Record<string, boolean>
  /** Referent:in: eigene Referate; null bei Reichweite „alle“ (R7) */
  ownReferate: string[] | null
  onClose: () => void
  /** Nach dem Speichern, mit dem neuen Status */
  onDone: (status: VolunteerStatus) => void
}

type Step = 'choose' | 'confirm' | 'leave'

const STATUSES: VolunteerStatus[] = ['active', 'dormant', 'left']
const today = () => new Date().toISOString().slice(0, 10)

// T045 (US-EA-08, R7): Status wählen (ohne den aktuellen), Datum (Standard heute); bei „ruhend“ und
// „ausgeschieden“ Bestätigung, wenn die Person auch in anderen Referaten tätig ist. Bei „ausgeschieden“
// folgt der Schritt Ausscheiden (T046, US-EA-09).
export function StatusDialog({ personId, personName, current, properties, writable, ownReferate, onClose, onDone }: Props) {
  const [step, setStep] = useState<Step>('choose')
  const [status, setStatus] = useState<VolunteerStatus>(STATUSES.find((s) => s !== current)!)
  const [validFrom, setValidFrom] = useState(today)
  const [otherReferate, setOtherReferate] = useState<string[]>([])
  const [plan, setPlan] = useState<LeavePlan | null>(null)
  const [selected, setSelected] = useState<string[]>([])
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  function startLeave() {
    const next = properties ? buildLeavePlan(properties, writable, validFrom) : { items: [], hints: [] }
    setPlan(next)
    setSelected(next.items.filter((i) => i.selectable).map((i) => i.property.id))
    setStep('leave')
  }

  async function save() {
    setPending(true)
    setError(null)
    try {
      const err =
        status === 'left' ? await leaveVolunteer(personId, validFrom, selected) : await changeVolunteerStatus(personId, status, validFrom)
      if (err) return setError(toMessage(err).text)
      onDone(status)
    } catch (caught) {
      setError(toMessage(caught).text)
    } finally {
      setPending(false)
    }
  }

  /** Nach dem Bestätigen bzw. ohne Bestätigung: „ausgeschieden“ → Ausscheiden, sonst speichern. */
  function proceed() {
    if (status === 'left') startLeave()
    else void save()
  }

  async function onChoose(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    if (!validFrom) return setError(MESSAGES.fieldRequired.replace('<Feld>', 'ab'))
    if (status === 'active') return proceed()

    // R7: andere Referate (Referent:in) bzw. mehr als ein Referat (Reichweite „alle“)
    setPending(true)
    const referate = await loadPersonReferate(personId)
    setPending(false)
    if (!referate) return setError(MESSAGES.unexpected)
    const others = ownReferate ? referate.filter((r) => !ownReferate.includes(r.id)) : referate.length > 1 ? referate : []
    if (others.length > 0) {
      setOtherReferate(others.map((r) => r.name))
      setStep('confirm')
      return
    }
    proceed()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Status ändern</DialogTitle>
          <DialogDescription>
            {personName} ist zurzeit {VOLUNTEER_STATUS_LABELS[current]}.
          </DialogDescription>
        </DialogHeader>

        {step === 'choose' && (
          <form id="ea-status-form" onSubmit={onChoose} noValidate className="flex flex-col gap-4">
            <fieldset className="flex flex-col gap-2">
              <legend className="mb-2 text-sm font-medium">Neuer Status</legend>
              {STATUSES.filter((s) => s !== current).map((s) => (
                <label key={s} className="flex items-center gap-2 text-sm">
                  <input
                    type="radio"
                    name="status"
                    value={s}
                    checked={status === s}
                    onChange={() => setStatus(s)}
                    className="size-4 accent-primary"
                  />
                  {VOLUNTEER_STATUS_LABELS[s]}
                </label>
              ))}
            </fieldset>
            <div className="flex flex-col gap-2">
              <Label htmlFor="ea-status-from">ab</Label>
              <Input id="ea-status-from" type="date" required value={validFrom} onChange={(e) => setValidFrom(e.target.value)} className="sm:w-48" />
            </div>
          </form>
        )}

        {step === 'confirm' && (
          <p className="text-sm">
            Die Person ist auch in {otherReferate.join(', ')} tätig. Der Status gilt für alle Referate.
          </p>
        )}

        {step === 'leave' && plan && properties && (
          <AusscheidenSchritt
            plan={plan}
            data={properties}
            selected={selected}
            leaveDate={validFrom}
            onToggle={(id, checked) => setSelected((s) => (checked ? [...s, id] : s.filter((x) => x !== id)))}
          />
        )}

        {error && (
          <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
            <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
            {error}
          </p>
        )}

        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          {step === 'choose' && (
            <Button type="submit" form="ea-status-form" disabled={pending}>
              {status === 'left' ? 'Weiter' : pending ? 'Speichern …' : 'Speichern'}
            </Button>
          )}
          {step === 'confirm' && (
            <Button type="button" onClick={proceed} disabled={pending}>
              {pending ? 'Speichern …' : 'Bestätigen'}
            </Button>
          )}
          {step === 'leave' && (
            <Button type="button" onClick={() => void save()} disabled={pending}>
              {pending ? 'Speichern …' : `Ausgeschieden zum ${formatDate(validFrom)}`}
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
