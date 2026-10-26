import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { PRIVACY_CONFIRM_TEXT, PRIVACY_NOTICE_URL, PRIVACY_NOTICE_VERSION } from '@/features/ez/config'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { FormError } from '@/features/gr/shared/ui'
import { DublettenDialog, type SimilarPerson } from '@/features/shared/DublettenDialog'
import { TK_MESSAGES } from '@/features/tk/errors'
import { tkRpc } from '@/features/tk/rpc'
import { MESSAGES } from '@/lib/errors'
import { formatDate, personName } from '@/lib/format'

type Props = {
  planId: string
  presentIds: string[]
  onClose: () => void
  /** Person in die Leitung übernehmen (Name für die Anzeige). */
  onAdd: (personId: string, name: string) => void
}

type Step = 'form' | 'duplicates' | 'reactivate'

function reactivateQuestion(hit: SimilarPerson): string {
  if (hit.volunteer_status === 'dormant') return 'Diese Person ist ruhend. Wieder als aktiv eintragen?'
  if (hit.volunteer_status === 'left') {
    return `Diese Person ist ausgeschieden${hit.left_since ? ` seit ${formatDate(hit.left_since)}` : ''}. Wieder als aktiv eintragen?`
  }
  return 'Diese Person ist noch nicht als Aktive:r geführt. Als aktiv eintragen?'
}

// T020 (US-TK-03 AK9, AK10; R23): externe Leitende aus der Planung anlegen – Pflicht-Häkchen nach Art. 13 DSGVO
// (Text und Link wie in der Anwesenheitserfassung) → Dublettenprüfung → vorhandene Person übernehmen bzw. wieder aktiv
// eintragen (tk_reactivate_leader) / „Trotzdem anlegen“ (tk_create_leader, Funktion Helfer:in im Referat der Planung).
// Aufbau wie NeuePersonDialog der Anwesenheitserfassung (plan.md P8; eigene Fassung, weil EZ die Anwesenheit speichert).
export function NeueLeitungDialog({ planId, presentIds, onClose, onAdd }: Props) {
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

  const newName = () => `${preferred.trim() || first.trim()} ${last.trim()}`

  async function create() {
    if (!confirmed) {
      setStep('form')
      return setError(TK_MESSAGES.privacyNotConfirmed)
    }
    setPending(true)
    const res = await tkRpc<string>('tk_create_leader', {
      p_plan_id: planId,
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
    onAdd(res.data, newName())
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    if (!first.trim() || !last.trim()) return setError(MESSAGES.nameRequired)
    setPending(true)
    const res = await tkRpc<SimilarPerson[]>('ad_find_similar_persons', { p_first: first.trim(), p_last: last.trim(), p_email: email.trim() || null })
    setPending(false)
    if (res.error) return setError(res.error.text)
    const present = new Set(presentIds)
    const found = (res.data ?? []).filter((h) => !present.has(h.person_id))
    if (found.length > 0) {
      setHits(found)
      return setStep('duplicates')
    }
    await create()
  }

  function takeExisting(hit: SimilarPerson) {
    if (hit.volunteer_status !== 'active') {
      setChosen(hit)
      return setStep('reactivate')
    }
    onAdd(hit.person_id, personName(hit))
  }

  async function reactivate() {
    if (!chosen) return
    setPending(true)
    const res = await tkRpc('tk_reactivate_leader', { p_plan_id: planId, p_person: chosen.person_id })
    setPending(false)
    if (res.error) return setError(res.error.text)
    onAdd(chosen.person_id, personName(chosen))
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
          <DialogDescription>
            Die Person wird als Aktive:r mit der Funktion Helfer:in im Referat der Planung angelegt. Den Trainersatz gibt es, sobald
            die Geschäftsstelle eine Lizenz im Ehrenamtsmanagement einträgt.
          </DialogDescription>
        </DialogHeader>
        <form id="tk-new-person" onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="tk-np-first">Vorname</Label>
            <Input id="tk-np-first" value={first} onChange={(e) => setFirst(e.target.value)} autoComplete="off" required />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="tk-np-last">Nachname</Label>
            <Input id="tk-np-last" value={last} onChange={(e) => setLast(e.target.value)} autoComplete="off" required />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="tk-np-preferred">Rufname (optional)</Label>
            <Input id="tk-np-preferred" value={preferred} onChange={(e) => setPreferred(e.target.value)} autoComplete="off" />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="tk-np-email">E-Mail (optional)</Label>
            <Input id="tk-np-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="off" />
          </div>
          <label className="flex items-start gap-3 text-sm">
            <input type="checkbox" checked={confirmed} onChange={(e) => setConfirmed(e.target.checked)} className="mt-0.5 size-5 shrink-0 accent-primary" />
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
          <Button type="submit" form="tk-new-person" disabled={pending}>
            {pending ? 'Wird geprüft …' : 'Anlegen'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
