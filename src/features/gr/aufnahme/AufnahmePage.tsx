import { useState, type FormEvent, type ReactNode } from 'react'
import { ChevronLeftIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useGrAccess } from '@/features/gr/access'
import { continueHref, STEPS, type AdmissionResult } from '@/features/gr/aufnahme/data'
import { isRunning } from '@/features/gr/gruppen/detail'
import { ErziehungsberechtigteAbschnitt, NotfallkontakteAbschnitt } from '@/features/gr/personen/Beziehungen'
import type { GrPerson } from '@/features/gr/personen/data'
import { FotoerlaubnisAbschnitt, GesundheitAbschnitt } from '@/features/gr/personen/Einwilligungen'
import {
  choiceArgs,
  contractPayload,
  EMPTY_CONTRACT,
  PARTICIPANT_FIELDS,
  PARTICIPANT_REQUIRED,
  type ContractForm,
} from '@/features/gr/personen/fields'
import { PersonWahl } from '@/features/gr/personen/PersonWahl'
import { VertragFelder } from '@/features/gr/personen/VertragFelder'
import { grRpc } from '@/features/gr/shared/rpc'
import { FormError, HintBadge, LoadFailed } from '@/features/gr/shared/ui'
import { MESSAGES } from '@/lib/errors'
import { supabase } from '@/lib/supabase'
import { personName, todayIso } from '@/lib/format'
import { cn } from '@/lib/utils'

// T035 (US-GR-06–10, US-GR-12): Assistent in fünf Schritten; jeder Schritt speichert sofort. Abbrechen ist jederzeit
// möglich – die Person bleibt dann unter „Aufnahmen offen“ (W7). Bei laufender Teilnahme in einer anderen Gruppe
// geht es nach Schritt 1 direkt zu Schritt 5.
export function AufnahmePage() {
  const result = useLoaderData() as AdmissionResult
  const navigate = useNavigate()
  const revalidator = useRevalidator()

  if (result.state !== 'ok') {
    return (
      <section className="flex flex-col gap-4">
        <Link to="/gr" className="inline-flex items-center gap-1 self-start text-sm text-muted-foreground hover:text-foreground">
          <ChevronLeftIcon aria-hidden="true" className="size-4" />
          Gruppen
        </Link>
        <LoadFailed text={result.state === 'not_found' ? 'Gruppe nicht gefunden.' : MESSAGES.unexpected} />
      </section>
    )
  }

  const { group, person, step } = result
  const goto = (n: number) => person && navigate(continueHref({ group_id: group.id, person_id: person.person.id }, n), { replace: true })
  const reload = () => revalidator.revalidate()

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <Link to={`/gr/gruppen/${group.id}`} className="inline-flex items-center gap-1 self-start text-sm text-muted-foreground hover:text-foreground">
          <ChevronLeftIcon aria-hidden="true" className="size-4" />
          {group.name}
        </Link>
        <h1 className="text-xl font-semibold">
          Teilnehmer:in aufnehmen{person && `: ${personName(person.person)}`}
        </h1>
      </div>

      <ol aria-label="Schritte" className="flex flex-wrap gap-x-4 gap-y-1 text-sm">
        {STEPS.map((label, i) => (
          <li key={label} aria-current={step === i + 1 ? 'step' : undefined} className={cn(step === i + 1 ? 'font-medium' : 'text-muted-foreground')}>
            {i + 1}. {label}
          </li>
        ))}
      </ol>

      {step === 1 || !person ? (
        <PersonStep groupId={group.id} />
      ) : (
        <>
          {step === 2 && (
            <StepFrame title="Erziehungsberechtigte" hint={person.needsGuardian ? 'Bitte mindestens eine erziehungsberechtigte Person angeben.' : null}>
              <ErziehungsberechtigteAbschnitt childId={person.person.id} guardians={person.guardians} editable onChanged={reload} />
            </StepFrame>
          )}
          {step === 3 && (
            <StepFrame title="Notfallkontakte" hint={person.emergencyContacts.length === 0 ? 'Kein Notfallkontakt hinterlegt.' : null}>
              <NotfallkontakteAbschnitt
                childId={person.person.id}
                contacts={person.emergencyContacts}
                guardians={person.guardians}
                editable
                onChanged={reload}
              />
            </StepFrame>
          )}
          {step === 4 && (
            <StepFrame title="Fotoerlaubnis, Einwilligung und Gesundheitsangaben">
              <FotoerlaubnisAbschnitt personId={person.person.id} rows={person.photoConsents} editable onChanged={reload} />
              <GesundheitAbschnitt
                personId={person.person.id}
                consents={person.healthConsents}
                note={person.healthNote}
                history={person.healthHistory}
                onChanged={reload}
              />
            </StepFrame>
          )}
          {step === 5 && <ContractStep groupId={group.id} groupName={group.name} person={person} />}

          <div className="flex flex-wrap gap-2 border-t pt-4">
            {step > 2 && (
              <Button variant="outline" onClick={() => goto(step - 1)} className="h-11 sm:h-8">
                Zurück
              </Button>
            )}
            {step < STEPS.length && (
              <Button onClick={() => goto(step + 1)} className="h-11 sm:h-8">
                Weiter
              </Button>
            )}
            {person.pending?.group_id === group.id && <CancelAdmission personId={person.person.id} groupId={group.id} />}
          </div>
        </>
      )}
    </section>
  )
}

function StepFrame({ title, hint, children }: { title: string; hint?: string | null; children: ReactNode }) {
  return (
    <div className="flex flex-col gap-4">
      <h2 className="font-medium">{title}</h2>
      {hint && (
        <span>
          <HintBadge>{hint}</HintBadge>
        </span>
      )}
      {children}
    </div>
  )
}

// Schritt 1: Person suchen oder neu (Dublettenprüfung; neue Teilnehmer:innen nur mit „Gruppen verwalten“)
function PersonStep({ groupId }: { groupId: string }) {
  const { canManage } = useGrAccess()
  const navigate = useNavigate()
  return (
    <div className="flex flex-col gap-4">
      <h2 className="font-medium">Person</h2>
      <PersonWahl
        idPrefix="gr-participant"
        fields={PARTICIPANT_FIELDS}
        required={PARTICIPANT_REQUIRED}
        allowNew={canManage}
        validate={(v) => (PARTICIPANT_REQUIRED.some((f) => !v[f].trim()) ? MESSAGES.grParticipantFieldsRequired : null)}
        submitLabel="Aufnahme beginnen"
        onChoose={async (choice) => {
          const result = await grRpc<string>('gr_start_admission', { p_group: groupId, ...choiceArgs(choice) })
          if (result.error !== null) return result.error
          // laufende Teilnahme in einer anderen Gruppe: direkt zu Teilnahme und Vertrag
          const { data } = await supabase
            .from('gr_memberships')
            .select('left_on')
            .eq('person_id', result.data)
            .neq('group_id', groupId)
          const elsewhere = (data ?? []).some((m: { left_on: string | null }) => isRunning(m.left_on))
          navigate(continueHref({ group_id: groupId, person_id: result.data }, elsewhere ? 5 : 2), { replace: true })
          return null
        }}
      />
    </div>
  )
}

// Schritt 5: Teilnahme und Vertrag in einer Transaktion (R16, gr_admit)
function ContractStep({ groupId, groupName, person }: { groupId: string; groupName: string; person: GrPerson }) {
  const navigate = useNavigate()
  const name = personName(person.person)
  const holders = [...person.guardians.map((g) => g.person), person.person]
  const [joinedOn, setJoinedOn] = useState(todayIso())
  const [contract, setContract] = useState<ContractForm>({
    ...EMPTY_CONTRACT,
    starts_on: todayIso(),
    purpose: `Beitrag ${groupName} ${name}`.slice(0, 140),
  })
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    if (!joinedOn) return setError(MESSAGES.grContractFieldsRequired)
    setPending(true)
    const result = await grRpc('gr_admit', { p_person: person.person.id, p_group: groupId, p_joined_on: joinedOn, p_contract: contractPayload(contract) })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    toast.success(`${name} ist in ${groupName} aufgenommen.`)
    navigate(`/gr/personen/${person.person.id}`)
  }

  return (
    <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
      <h2 className="font-medium">Teilnahme und Vertrag</h2>
      <div className="flex flex-col gap-2">
        <Label htmlFor="gr-joined-on">Eintrittsdatum</Label>
        <Input id="gr-joined-on" type="date" value={joinedOn} onChange={(e) => setJoinedOn(e.target.value)} className="sm:w-44" />
      </div>
      <VertragFelder value={contract} onChange={setContract} holders={holders} />
      <FormError text={error} />
      <Button type="submit" disabled={pending} className="h-11 self-start sm:h-8">
        {pending ? 'Speichern …' : 'Aufnehmen'}
      </Button>
    </form>
  )
}

function CancelAdmission({ personId, groupId }: { personId: string; groupId: string }) {
  const navigate = useNavigate()
  const [open, setOpen] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function cancel() {
    setPending(true)
    const result = await grRpc('gr_cancel_admission', { p_person: personId })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    navigate(`/gr/gruppen/${groupId}`, { replace: true })
  }

  return (
    <>
      <Button variant="ghost" onClick={() => setOpen(true)} className="h-11 sm:ml-auto sm:h-8">
        Aufnahme abbrechen
      </Button>
      <Dialog open={open} onOpenChange={(next) => !next && !pending && setOpen(false)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Aufnahme abbrechen</DialogTitle>
            <DialogDescription>Die Person wird aus Gruppen entfernt. Ihre Daten bleiben gespeichert.</DialogDescription>
          </DialogHeader>
          <FormError text={error} />
          <DialogFooter>
            <Button variant="outline" onClick={() => setOpen(false)} disabled={pending}>
              Zurück
            </Button>
            <Button variant="destructive" onClick={() => void cancel()} disabled={pending}>
              {pending ? 'Wird abgebrochen …' : 'Aufnahme abbrechen'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
