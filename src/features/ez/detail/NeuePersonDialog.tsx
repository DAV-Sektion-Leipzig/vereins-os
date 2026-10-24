import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { PRIVACY_CONFIRM_TEXT, PRIVACY_NOTICE_URL, PRIVACY_NOTICE_VERSION } from '@/features/ez/config'
import type { Attendance } from '@/features/ez/detail/data'
import { EZ_MESSAGES } from '@/features/ez/errors'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { ezRpc } from '@/features/ez/shared/rpc'
import { DublettenDialog, type SimilarPerson } from '@/features/shared/DublettenDialog'
import { FormError } from '@/features/gr/shared/ui'
import { MESSAGES } from '@/lib/errors'
import { formatDate, personName } from '@/lib/format'

type Props = {
  eventId: string
  attendances: Attendance[]
  onClose: () => void
  /** Vorhandene aktive Person als Helfer:in eintragen; gibt eine Fehlermeldung zurück oder null. */
  onAddExisting: (personId: string) => Promise<string | null>
  onDone: () => void
}

type Step = 'form' | 'duplicates' | 'reactivate'

/** Rückfrage nach R31 (Wortlaut der Rückfrage für Personen ohne Ehrenamtsstatus: Vorschlag, Abnahme bestätigt ihn). */
function reactivateQuestion(hit: SimilarPerson): string {
  if (hit.volunteer_status === 'dormant') return 'Diese Person ist ruhend. Wieder als aktiv eintragen?'
  if (hit.volunteer_status === 'left') {
    return `Diese Person ist ausgeschieden${hit.left_since ? ` seit ${formatDate(hit.left_since)}` : ''}. Wieder als aktiv eintragen?`
  }
  return 'Diese Person ist noch nicht als Aktive:r geführt. Als aktiv eintragen?'
}

// T030 (US-EZ-11, R29, R31): Neue Person beim Arbeitseinsatz mit Pflicht-Häkchen „Person informiert“ →
// Dublettenprüfung (ad_find_similar_persons) → „Diese Person eintragen“ (aktiv: Anwesenheit; ruhend, ausgeschieden,
// ohne Status: Rückfrage, dann ez_reactivate_helper) / „Trotzdem anlegen“ (ez_create_helper) / „Abbrechen“.
export function NeuePersonDialog({ eventId, attendances, onClose, onAddExisting, onDone }: Props) {
  const [first, setFirst] = useState('')
  const [last, setLast] = useState('')
  const [preferred, setPreferred] = useState('')
  const [email, setEmail] = useState('')
  const [confirmed, setConfirmed] = useState(false)
  const [step, setStep] = useState<Step>('form')
  const [hits, setHits] = useState<SimilarPerson[]>([])
  const [chosen, setChosen] = useState<SimilarPerson | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function create() {
    // „Anlegen“ nur mit Häkchen (R29); für vorhandene Personen ist es nicht nötig
    if (!confirmed) {
      setStep('form')
      return setError(EZ_MESSAGES.privacyNotConfirmed)
    }
    setPending(true)
    const res = await ezRpc<string>('ez_create_helper', {
      p_event: eventId,
      p_first: first.trim(),
      p_last: last.trim(),
      p_preferred: preferred.trim() || null,
      p_email: email.trim() || null,
      p_privacy_confirmed: true,
      p_notice_version: PRIVACY_NOTICE_VERSION,
    })
    setPending(false)
    if (res.error) {
      setStep('form')
      return setError(res.error.text)
    }
    onDone()
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    if (!first.trim() || !last.trim()) return setError(MESSAGES.nameRequired)
    setPending(true)
    const res = await ezRpc<SimilarPerson[]>('ad_find_similar_persons', {
      p_first: first.trim(),
      p_last: last.trim(),
      p_email: email.trim() || null,
    })
    setPending(false)
    if (res.error) return setError(res.error.text)
    const present = new Set(attendances.map((a) => a.person_id))
    const found = (res.data ?? []).filter((h) => !present.has(h.person_id))
    if (found.length > 0) {
      setHits(found)
      return setStep('duplicates')
    }
    await create()
  }

  async function takeExisting(hit: SimilarPerson) {
    if (hit.volunteer_status !== 'active') {
      setChosen(hit)
      return setStep('reactivate')
    }
    setPending(true)
    const message = await onAddExisting(hit.person_id)
    setPending(false)
    if (message) {
      setStep('form')
      return setError(message)
    }
    onDone()
  }

  async function reactivate() {
    if (!chosen) return
    setPending(true)
    const res = await ezRpc('ez_reactivate_helper', { p_event: eventId, p_person: chosen.person_id })
    setPending(false)
    if (res.error) return setError(res.error.text)
    onDone()
  }

  if (step === 'duplicates') {
    return (
      <DublettenDialog
        open
        hits={hits}
        pending={pending}
        onCreateAnyway={create}
        onCancel={() => setStep('form')}
        hitAction={(hit) => (
          <Button variant="outline" size="sm" onClick={() => takeExisting(hit)} disabled={pending} className="h-11 sm:h-7">
            Diese Person eintragen
          </Button>
        )}
      />
    )
  }

  if (step === 'reactivate' && chosen) {
    return (
      <ConfirmDialog
        title={personName(chosen)}
        confirmLabel="Als aktiv eintragen"
        pendingLabel="Wird eingetragen …"
        pending={pending}
        error={error}
        onConfirm={reactivate}
        onClose={() => {
          setError(null)
          setStep('duplicates')
        }}
      >
        {reactivateQuestion(chosen)}
      </ConfirmDialog>
    )
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Neue Person anlegen</DialogTitle>
          <DialogDescription>Die Person wird als Aktive:r mit der Funktion Helfer:in angelegt und als anwesend eingetragen.</DialogDescription>
        </DialogHeader>
        <form id="ez-new-person" onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="ez-np-first">Vorname</Label>
            <Input id="ez-np-first" value={first} onChange={(e) => setFirst(e.target.value)} autoComplete="off" required />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ez-np-last">Nachname</Label>
            <Input id="ez-np-last" value={last} onChange={(e) => setLast(e.target.value)} autoComplete="off" required />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ez-np-preferred">Rufname (optional)</Label>
            <Input id="ez-np-preferred" value={preferred} onChange={(e) => setPreferred(e.target.value)} autoComplete="off" />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ez-np-email">E-Mail (optional)</Label>
            <Input id="ez-np-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="off" />
          </div>
          <label className="flex items-start gap-3 text-sm">
            <input
              type="checkbox"
              checked={confirmed}
              onChange={(e) => setConfirmed(e.target.checked)}
              className="mt-0.5 size-5 shrink-0 accent-primary"
            />
            <span>
              {PRIVACY_CONFIRM_TEXT}
              {PRIVACY_NOTICE_URL && (
                <>
                  {' '}
                  <a href={PRIVACY_NOTICE_URL} target="_blank" rel="noreferrer" className="underline underline-offset-4">
                    Datenschutzhinweise
                  </a>
                </>
              )}
            </span>
          </label>
        </form>
        <FormError text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="submit" form="ez-new-person" disabled={pending}>
            {pending ? 'Wird geprüft …' : 'Anlegen'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
