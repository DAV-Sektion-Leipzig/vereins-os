import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import type { GroupDetail } from '@/features/gr/gruppen/detail'
import { FormError, selectClassName } from '@/features/gr/shared/ui'
import { grRpc, loadReferate, type ReferatOption } from '@/features/gr/shared/rpc'
import { MESSAGES } from '@/lib/errors'
import { todayIso, WEEKDAYS } from '@/lib/format'

/** Name und Referat (R1, R21); Referat-Auswahl nur aktive, beim Ändern zusätzlich das bisherige. */
function NameReferatFields({
  name,
  setName,
  referat,
  setReferat,
  referate,
  currentReferat,
}: {
  name: string
  setName: (v: string) => void
  referat: string
  setReferat: (v: string) => void
  referate: ReferatOption[]
  currentReferat?: string
}) {
  return (
    <>
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-group-name">Name</Label>
        <Input id="gr-group-name" value={name} onChange={(e) => setName(e.target.value)} maxLength={80} required />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-group-referat">Referat</Label>
        <select id="gr-group-referat" value={referat} onChange={(e) => setReferat(e.target.value)} className={selectClassName} required>
          <option value="">bitte wählen</option>
          {referate
            .filter((r) => r.is_active || r.id === currentReferat)
            .map((r) => (
              <option key={r.id} value={r.id}>
                {r.name}
              </option>
            ))}
        </select>
      </div>
    </>
  )
}

function useReferate() {
  const [referate, setReferate] = useState<ReferatOption[] | null>(null)
  const [failed, setFailed] = useState(false)
  useEffect(() => {
    void loadReferate().then((r) => (r ? setReferate(r) : setFailed(true)))
  }, [])
  return { referate: referate ?? [], failed }
}

// T028 (US-GR-03): /gr/gruppen/neu – Name, Referat (nur aktive), optional erste Trainingszeit
export function GruppeNeuPage() {
  const navigate = useNavigate()
  const { referate, failed } = useReferate()
  const [name, setName] = useState('')
  const [referat, setReferat] = useState('')
  const [weekday, setWeekday] = useState('')
  const [starts, setStarts] = useState('')
  const [ends, setEnds] = useState('')
  const [validFrom, setValidFrom] = useState(todayIso())
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    if (!name.trim() || !referat) return setError(MESSAGES.grGroupFieldsRequired)
    const withTime = Boolean(weekday || starts || ends)
    if (withTime && (!weekday || !starts || !ends || !validFrom)) return setError(MESSAGES.grTrainingTimeRequired)
    if (withTime && ends <= starts) return setError(MESSAGES.grTrainingTimeEnd)

    setPending(true)
    const saved = await grRpc<string>('gr_save_group', { p_id: null, p_name: name, p_referat_id: referat })
    if (saved.error !== null) {
      setPending(false)
      return setError(saved.error)
    }
    if (withTime) {
      const time = await grRpc('gr_add_training_time', {
        p_group: saved.data,
        p_weekday: Number(weekday),
        p_starts: starts,
        p_ends: ends,
        p_valid_from: validFrom,
      })
      if (time.error !== null) {
        setPending(false)
        // Gruppe ist angelegt; Trainingszeit im Detail nachtragen
        return navigate(`/gr/gruppen/${saved.data}?reiter=trainingszeiten`, { state: { error: time.error } })
      }
    }
    navigate(`/gr/gruppen/${saved.data}`)
  }

  return (
    <section className="flex flex-col gap-6">
      <h1 className="text-xl font-semibold">Gruppe anlegen</h1>
      <form onSubmit={onSubmit} noValidate className="flex max-w-xl flex-col gap-4">
        <NameReferatFields name={name} setName={setName} referat={referat} setReferat={setReferat} referate={referate} />
        <fieldset className="flex flex-col gap-3 rounded-xl border p-4">
          <legend className="px-1 text-sm font-medium">Erste Trainingszeit (optional)</legend>
          <TrainingTimeFields
            weekday={weekday}
            setWeekday={setWeekday}
            starts={starts}
            setStarts={setStarts}
            ends={ends}
            setEnds={setEnds}
            validFrom={validFrom}
            setValidFrom={setValidFrom}
            optional
          />
        </fieldset>
        <FormError text={failed ? MESSAGES.unexpected : error} />
        <div className="flex flex-wrap gap-2">
          <Button type="submit" disabled={pending} className="h-11 sm:h-8">
            {pending ? 'Speichern …' : 'Speichern'}
          </Button>
          <Button type="button" variant="outline" onClick={() => navigate('/gr')} disabled={pending} className="h-11 sm:h-8">
            Abbrechen
          </Button>
        </div>
      </form>
    </section>
  )
}

export function TrainingTimeFields({
  weekday,
  setWeekday,
  starts,
  setStarts,
  ends,
  setEnds,
  validFrom,
  setValidFrom,
  validFromLabel = 'gültig von',
  optional = false,
}: {
  weekday: string
  setWeekday: (v: string) => void
  starts: string
  setStarts: (v: string) => void
  ends: string
  setEnds: (v: string) => void
  validFrom?: string
  setValidFrom?: (v: string) => void
  validFromLabel?: string
  optional?: boolean
}) {
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-tt-weekday">Wochentag</Label>
        <select id="gr-tt-weekday" value={weekday} onChange={(e) => setWeekday(e.target.value)} className={selectClassName}>
          <option value="">{optional ? 'keine' : 'bitte wählen'}</option>
          {WEEKDAYS.map((d) => (
            <option key={d.value} value={d.value}>
              {d.long}
            </option>
          ))}
        </select>
      </div>
      {setValidFrom && (
        <div className="flex flex-col gap-2">
          <Label htmlFor="gr-tt-from">{validFromLabel}</Label>
          <Input id="gr-tt-from" type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} className="sm:w-44" />
        </div>
      )}
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-tt-starts">Beginn</Label>
        <Input id="gr-tt-starts" type="time" value={starts} onChange={(e) => setStarts(e.target.value)} className="sm:w-32" />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-tt-ends">Ende</Label>
        <Input id="gr-tt-ends" type="time" value={ends} onChange={(e) => setEnds(e.target.value)} className="sm:w-32" />
      </div>
    </div>
  )
}

// T028 (US-GR-03): Gruppe ändern (Name, Referat)
export function GruppeAendernDialog({ group, onClose, onDone }: { group: GroupDetail; onClose: () => void; onDone: () => void }) {
  const { referate } = useReferate()
  const [name, setName] = useState(group.name)
  const [referat, setReferat] = useState(group.referat_id)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    if (!name.trim() || !referat) return setError(MESSAGES.grGroupFieldsRequired)
    setPending(true)
    const result = await grRpc('gr_save_group', { p_id: group.id, p_name: name, p_referat_id: referat })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    onDone()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Gruppe ändern</DialogTitle>
          <DialogDescription>Name und Referat der Gruppe.</DialogDescription>
        </DialogHeader>
        <form id="gr-group-edit" onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <NameReferatFields
            name={name}
            setName={setName}
            referat={referat}
            setReferat={setReferat}
            referate={referate}
            currentReferat={group.referat_id}
          />
        </form>
        <FormError text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="submit" form="gr-group-edit" disabled={pending}>
            {pending ? 'Speichern …' : 'Speichern'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

// T030 (US-GR-04, R9, A12): Auflösen mit Datum ≤ heute und Bestätigung
export function AufloesenDialog({ group, onClose, onDone }: { group: GroupDetail; onClose: () => void; onDone: () => void }) {
  const [date, setDate] = useState(todayIso())
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    if (!date) return setError(MESSAGES.grConsentDateRequired)
    if (date > todayIso()) return setError(MESSAGES.grDateInFuture)
    setPending(true)
    const result = await grRpc<{ starts_after_dissolution: unknown[] }>('gr_dissolve_group', { p_id: group.id, p_dissolved_on: date })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    // Einträge, die erst nach dem Auflösungsdatum beginnen, bleiben unverändert (plan.md H5)
    const later = result.data?.starts_after_dissolution?.length ?? 0
    if (later > 0) toast.info(`${later} ${later === 1 ? 'Eintrag beginnt' : 'Einträge beginnen'} erst nach der Auflösung und ${later === 1 ? 'bleibt' : 'bleiben'} unverändert.`)
    onDone()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Gruppe auflösen</DialogTitle>
          <DialogDescription>
            {group.name} wird zum gewählten Tag aufgelöst. Laufende Funktionen und Trainingszeiten enden an diesem Tag. Danach ist die Gruppe
            nur noch lesbar.
          </DialogDescription>
        </DialogHeader>
        <form id="gr-group-dissolve" onSubmit={onSubmit} noValidate className="flex flex-col gap-2">
          <Label htmlFor="gr-dissolve-date">aufgelöst am</Label>
          <Input id="gr-dissolve-date" type="date" max={todayIso()} value={date} onChange={(e) => setDate(e.target.value)} className="sm:w-44" />
        </form>
        <FormError text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="submit" form="gr-group-dissolve" variant="destructive" disabled={pending}>
            {pending ? 'Wird aufgelöst …' : 'Gruppe auflösen'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
