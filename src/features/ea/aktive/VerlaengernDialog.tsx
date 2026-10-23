import { useEffect, useId, useState, type FormEvent } from 'react'
import { CircleAlertIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import type { PersonProperty, PropertyTypeWithFields } from '@/features/ad/personen/data'
import { deriveValidUntil, renewProperty } from '@/features/ea/aktive/data'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDate } from '@/lib/format'

type Props = {
  property: PersonProperty
  type: PropertyTypeWithFields
  /** Bezeichnung der Qualifikationsart, z. B. „TCSPI – Trainer:in C Sportklettern“ */
  qualificationLabel: string
  onClose: () => void
  onDone: () => void
}

const today = () => new Date().toISOString().slice(0, 10)

function capitalize(s: string) {
  return s.charAt(0).toUpperCase() + s.slice(1)
}

// T044 (US-EA-07 AK3, R5, R6): Verlängern legt eine neue Eigenschaft an; die bisherige endet am Vortag.
// „gültig bis“ wird nach R5 vorbelegt, solange der Nutzer es nicht selbst ändert.
export function VerlaengernDialog({ property, type, qualificationLabel, onClose, onDone }: Props) {
  const id = useId()
  const [validFrom, setValidFrom] = useState(today)
  const [lastTraining, setLastTraining] = useState('')
  const [validUntil, setValidUntil] = useState('')
  const [validUntilTouched, setValidUntilTouched] = useState(false)
  const [withTraining, setWithTraining] = useState(false)
  const [trainingYear, setTrainingYear] = useState('')
  const [trainingTitle, setTrainingTitle] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  const qualificationType = String(property.field_values.qualification_type ?? '')
  const hasLastTraining = type.fields.some((f) => f.key === 'last_training')
  const validUntilRequired = type.fields.find((f) => f.key === 'valid_until')?.is_required ?? false
  const fromLabel = type.valid_from_label ?? 'gültig von'

  useEffect(() => {
    if (validUntilTouched || !qualificationType || !validFrom) return
    let current = true
    deriveValidUntil({ qualificationType, validFrom, lastTraining: lastTraining || null })
      .then((value) => current && setValidUntil(value ?? ''))
      .catch(() => undefined)
    return () => {
      current = false
    }
  }, [validUntilTouched, qualificationType, validFrom, lastTraining])

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    // R6 vor dem Aufruf: neues Datum nach dem bisherigen
    if (!validFrom || validFrom <= property.valid_from) return setError(MESSAGES.renewInvalid)
    if (validUntilRequired && !validUntil) return setError(MESSAGES.fieldRequired.replace('<Feld>', 'gültig bis'))
    if (withTraining && (!trainingYear || !trainingTitle.trim())) {
      return setError(MESSAGES.fieldRequired.replace('<Feld>', trainingYear ? 'Titel' : 'Jahr'))
    }
    setPending(true)
    try {
      const err = await renewProperty(property.id, {
        validFrom,
        lastTraining,
        validUntil,
        training: withTraining ? { year: Number(trainingYear), title: trainingTitle.trim() } : null,
      })
      if (err) return setError(toMessage(err).text)
      onDone()
    } catch (caught) {
      setError(toMessage(caught).text)
    } finally {
      setPending(false)
    }
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>{type.name} verlängern</DialogTitle>
            <DialogDescription>
              {qualificationLabel} · bisher {fromLabel} {formatDate(property.valid_from)}. Die bisherige Angabe endet am Vortag
              und bleibt in der Historie.
            </DialogDescription>
          </DialogHeader>

          <div className="flex flex-col gap-2">
            <Label htmlFor={`${id}-from`}>{capitalize(fromLabel)}</Label>
            <Input id={`${id}-from`} type="date" required value={validFrom} onChange={(e) => setValidFrom(e.target.value)} />
          </div>
          {hasLastTraining && (
            <div className="flex flex-col gap-2">
              <Label htmlFor={`${id}-training-date`}>
                Letzte Fortbildung <span className="font-normal text-muted-foreground">(optional)</span>
              </Label>
              <Input id={`${id}-training-date`} type="date" value={lastTraining} onChange={(e) => setLastTraining(e.target.value)} />
            </div>
          )}
          <div className="flex flex-col gap-2">
            <Label htmlFor={`${id}-until`}>
              Gültig bis{!validUntilRequired && <span className="font-normal text-muted-foreground"> (optional)</span>}
            </Label>
            <Input
              id={`${id}-until`}
              type="date"
              required={validUntilRequired}
              value={validUntil}
              onChange={(e) => {
                setValidUntilTouched(true)
                setValidUntil(e.target.value)
              }}
            />
          </div>

          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={withTraining}
              onChange={(e) => {
                setWithTraining(e.target.checked)
                if (e.target.checked && !trainingYear) setTrainingYear(validFrom.slice(0, 4))
              }}
              className="size-4 accent-primary"
            />
            Fortbildung anlegen
          </label>
          {withTraining && (
            <div className="grid gap-4 sm:grid-cols-[6rem_1fr]">
              <div className="flex flex-col gap-2">
                <Label htmlFor={`${id}-year`}>Jahr</Label>
                <Input
                  id={`${id}-year`}
                  type="number"
                  inputMode="numeric"
                  min={1900}
                  max={2100}
                  step={1}
                  value={trainingYear}
                  onChange={(e) => setTrainingYear(e.target.value)}
                />
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor={`${id}-title`}>Titel</Label>
                <Input id={`${id}-title`} value={trainingTitle} onChange={(e) => setTrainingTitle(e.target.value)} autoComplete="off" />
              </div>
            </div>
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
            <Button type="submit" disabled={pending}>
              {pending ? 'Speichern …' : 'Verlängern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
