import { useState, type FormEvent } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { timeLabel, type TrainingTime } from '@/features/gr/gruppen/detail'
import { TrainingTimeFields } from '@/features/gr/gruppen/GruppeFormular'
import { grRpc } from '@/features/gr/shared/rpc'
import { FormError } from '@/features/gr/shared/ui'
import { MESSAGES } from '@/lib/errors'
import { formatClock, formatDate, todayIso } from '@/lib/format'

export type TrainingTimeMode = { kind: 'add' } | { kind: 'change'; time: TrainingTime } | { kind: 'end'; time: TrainingTime }

const OVERLAP = 'Diese Trainingszeit überschneidet sich mit einer anderen.'

// T029 (US-GR-18, R18, R19, A13): Trainingszeit hinzufügen, „Ändern ab“ oder beenden. Wochentag und Uhrzeit
// einer gespeicherten Trainingszeit sind nicht änderbar; „Ändern ab“ beendet sie am Vortag und legt eine neue an.
export function TrainingszeitDialog({
  groupId,
  mode,
  onClose,
  onDone,
}: {
  groupId: string
  mode: TrainingTimeMode
  onClose: () => void
  onDone: () => void
}) {
  const old = mode.kind === 'add' ? null : mode.time
  const [weekday, setWeekday] = useState(old ? String(old.weekday) : '')
  const [starts, setStarts] = useState(old ? formatClock(old.starts_at) : '')
  const [ends, setEnds] = useState(old ? formatClock(old.ends_at) : '')
  const [validFrom, setValidFrom] = useState(todayIso())
  const [validTo, setValidTo] = useState(mode.kind === 'end' ? (mode.time.valid_to ?? todayIso()) : '')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    if (mode.kind !== 'end') {
      if (!weekday || !starts || !ends || !validFrom) return setError(MESSAGES.grTrainingTimeRequired)
      if (ends <= starts) return setError(MESSAGES.grTrainingTimeEnd)
    }
    if (mode.kind === 'add' && validTo && validTo < validFrom) return setError(MESSAGES.validRange)

    setPending(true)
    const result =
      mode.kind === 'add'
        ? await grRpc<{ overlap: boolean }>('gr_add_training_time', {
            p_group: groupId,
            p_weekday: Number(weekday),
            p_starts: starts,
            p_ends: ends,
            p_valid_from: validFrom,
            p_valid_to: validTo || null,
          })
        : mode.kind === 'change'
          ? await grRpc<{ overlap: boolean }>('gr_change_training_time', {
              p_id: mode.time.id,
              p_from: validFrom,
              p_weekday: Number(weekday),
              p_starts: starts,
              p_ends: ends,
            })
          : await grRpc<null>('gr_end_training_time', { p_id: mode.time.id, p_valid_to: validTo || null })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    // R19: Hinweis, Speichern bleibt möglich
    if (result.data && typeof result.data === 'object' && result.data.overlap) toast.warning(OVERLAP)
    onDone()
  }

  const title = mode.kind === 'add' ? 'Trainingszeit hinzufügen' : mode.kind === 'change' ? 'Trainingszeit ändern ab' : 'Trainingszeit beenden'

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>
            {mode.kind === 'add' && 'Wochentag und Uhrzeit sind nach dem Speichern nicht mehr änderbar, nur über „Ändern ab“.'}
            {mode.kind === 'change' &&
              `${timeLabel(mode.time)} (gültig von ${formatDate(mode.time.valid_from)}) endet am Vortag; ab dem Datum gilt die neue Zeit.`}
            {mode.kind === 'end' && `${timeLabel(mode.time)} (gültig von ${formatDate(mode.time.valid_from)})`}
          </DialogDescription>
        </DialogHeader>
        <form id="gr-tt-form" onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          {mode.kind !== 'end' && (
            <TrainingTimeFields
              weekday={weekday}
              setWeekday={setWeekday}
              starts={starts}
              setStarts={setStarts}
              ends={ends}
              setEnds={setEnds}
              validFrom={validFrom}
              setValidFrom={setValidFrom}
              validFromLabel={mode.kind === 'change' ? 'ändern ab' : 'gültig von'}
            />
          )}
          {mode.kind !== 'change' && (
            <div className="flex flex-col gap-2">
              <Label htmlFor="gr-tt-to">{mode.kind === 'add' ? 'gültig bis (optional)' : 'gültig bis'}</Label>
              <Input id="gr-tt-to" type="date" value={validTo} onChange={(e) => setValidTo(e.target.value)} className="sm:w-44" />
            </div>
          )}
        </form>
        <FormError text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="submit" form="gr-tt-form" disabled={pending}>
            {pending ? 'Speichern …' : 'Speichern'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
