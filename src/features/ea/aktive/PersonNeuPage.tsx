import { useRef, useState, type FormEvent } from 'react'
import { ChevronLeftIcon, CircleAlertIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { findSimilarPersons } from '@/features/ad/personen/data'
import {
  activatePerson,
  createVolunteer,
  type NewVolunteerData,
  type VolunteerInput,
} from '@/features/ea/aktive/data'
import { DublettenDialog, type SimilarPerson } from '@/features/shared/DublettenDialog'
import { MESSAGES, toMessage } from '@/lib/errors'

const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm'

const today = () => new Date().toISOString().slice(0, 10)

// T040, T041 (US-EA-05, US-EA-10): Person mit erster Zuordnung anlegen; Dublettenprüfung mit Rückkehr und Übernahme.
export function PersonNeuPage() {
  const { types, referate, referatRequired } = useLoaderData() as NewVolunteerData
  const navigate = useNavigate()
  const [input, setInput] = useState<VolunteerInput>({
    first: '',
    preferred: '',
    last: '',
    typeId: referatRequired ? (types[0]?.id ?? '') : '',
    systemKey: referatRequired ? (types[0]?.systemKey ?? '') : '',
    value: '',
    // Referent:in mit nur einem eigenen Referat: vorbelegt
    referatId: referatRequired && referate.length === 1 ? referate[0].id : '',
    since: today(),
  })
  const [error, setError] = useState<string | null>(null)
  const [hits, setHits] = useState<SimilarPerson[] | null>(null)
  const [pending, setPending] = useState(false)
  const firstRef = useRef<HTMLInputElement>(null)

  const type = types.find((t) => t.id === input.typeId)
  const nameMissing = error === MESSAGES.nameRequired

  function set<K extends keyof VolunteerInput>(key: K, value: VolunteerInput[K]) {
    setInput((current) => ({ ...current, [key]: value }))
  }

  function selectType(id: string) {
    const next = types.find((t) => t.id === id)
    setInput((current) => ({ ...current, typeId: id, systemKey: next?.systemKey ?? '', value: '' }))
  }

  /** Prüfung vor dem Aufruf: Name (R4 AD), Zuordnung im eigenen Referat (R3), Wert der Zuordnung. */
  function validate(): string | null {
    if (!input.first.trim() || !input.last.trim()) return MESSAGES.nameRequired
    if (referatRequired && (!input.typeId || !input.referatId)) return MESSAGES.createReferatRequired
    if (type && !input.value) return MESSAGES.fieldRequired.replace('<Feld>', type.name)
    return null
  }

  async function run(action: () => Promise<{ id: string | null; error: unknown }>) {
    setPending(true)
    setError(null)
    try {
      const result = await action()
      if (result.error || !result.id) {
        setError(toMessage(result.error).text)
        setHits(null)
        return
      }
      navigate(`/ea/aktive/${result.id}`, { replace: true })
    } catch (caught) {
      setError(toMessage(caught).text)
      setHits(null)
    } finally {
      setPending(false)
    }
  }

  const create = () => run(() => createVolunteer(input))

  const activate = (hit: SimilarPerson) =>
    run(async () => {
      const err = await activatePerson(hit.person_id, input)
      return { id: err ? null : hit.person_id, error: err }
    })

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const problem = validate()
    if (problem) {
      setError(problem)
      if (problem === MESSAGES.nameRequired) firstRef.current?.focus()
      return
    }
    setPending(true)
    setError(null)
    try {
      const similar = await findSimilarPersons(input.first, input.last, '')
      if (similar.error) return setError(toMessage(similar.error).text)
      if (similar.hits.length > 0) return setHits(similar.hits)
    } catch (caught) {
      return setError(toMessage(caught).text)
    } finally {
      setPending(false)
    }
    await create()
  }

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <Link
          to="/ea/aktive"
          className="inline-flex items-center gap-1 self-start rounded-md text-sm text-muted-foreground underline-offset-4 outline-none hover:text-foreground hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring focus-visible:outline-solid"
        >
          <ChevronLeftIcon aria-hidden="true" className="size-4" />
          Aktive
        </Link>
        <h1 className="text-xl font-semibold">Person anlegen</h1>
      </div>

      <form className="flex max-w-md flex-col gap-6" onSubmit={onSubmit} noValidate>
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="ea-first">Vorname</Label>
            <Input
              id="ea-first"
              ref={firstRef}
              required
              value={input.first}
              onChange={(e) => set('first', e.target.value)}
              aria-invalid={nameMissing || undefined}
              aria-describedby={nameMissing ? 'ea-person-error' : undefined}
              autoComplete="off"
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ea-preferred">
              Rufname <span className="font-normal text-muted-foreground">(optional)</span>
            </Label>
            <Input id="ea-preferred" value={input.preferred} onChange={(e) => set('preferred', e.target.value)} autoComplete="off" />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ea-last">Nachname</Label>
            <Input
              id="ea-last"
              required
              value={input.last}
              onChange={(e) => set('last', e.target.value)}
              aria-invalid={nameMissing || undefined}
              aria-describedby={nameMissing ? 'ea-person-error' : undefined}
              autoComplete="off"
            />
          </div>
        </div>

        <fieldset className="flex flex-col gap-4">
          <legend className="mb-1 font-medium">
            Erste Zuordnung{' '}
            {!referatRequired && <span className="font-normal text-muted-foreground">(optional)</span>}
          </legend>
          <div className="flex flex-col gap-2">
            <Label htmlFor="ea-type">Art</Label>
            <select id="ea-type" value={input.typeId} onChange={(e) => selectType(e.target.value)} className={selectClassName}>
              {!referatRequired && <option value="">ohne Zuordnung</option>}
              {types.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </select>
          </div>
          {type && (
            <>
              <div className="flex flex-col gap-2">
                <Label htmlFor="ea-value">{type.name}</Label>
                <select id="ea-value" value={input.value} onChange={(e) => set('value', e.target.value)} className={selectClassName}>
                  <option value="">– bitte wählen –</option>
                  {type.values.map((v) => (
                    <option key={v} value={v}>
                      {v}
                    </option>
                  ))}
                </select>
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="ea-referat">
                  Referat {!referatRequired && <span className="font-normal text-muted-foreground">(optional)</span>}
                </Label>
                <select id="ea-referat" value={input.referatId} onChange={(e) => set('referatId', e.target.value)} className={selectClassName}>
                  <option value="">{referatRequired ? '– bitte wählen –' : 'ohne Referat'}</option>
                  {referate.map((r) => (
                    <option key={r.id} value={r.id}>
                      {r.name}
                    </option>
                  ))}
                </select>
              </div>
            </>
          )}
          <div className="flex flex-col gap-2">
            <Label htmlFor="ea-since">aktiv seit</Label>
            <Input id="ea-since" type="date" value={input.since} onChange={(e) => set('since', e.target.value)} className="sm:w-48" />
          </div>
        </fieldset>

        {error && <ErrorMessage text={error} />}

        <div className="flex flex-wrap gap-3">
          <Button type="submit" disabled={pending}>
            {pending ? 'Speichern …' : 'Speichern'}
          </Button>
          <Button variant="outline" asChild>
            <Link to="/ea/aktive">Abbrechen</Link>
          </Button>
        </div>
      </form>

      <DublettenDialog
        open={hits !== null}
        hits={hits ?? []}
        pending={pending}
        onCreateAnyway={create}
        onCancel={() => setHits(null)}
        hitAction={(hit) => (
          <>
            {hit.is_visible && hit.volunteer_status !== null && (
              <Button variant="outline" size="sm" asChild>
                <Link to={`/ea/aktive/${hit.person_id}`}>Vorhandene Person öffnen</Link>
              </Button>
            )}
            {hit.volunteer_status === 'left' && (
              <Button variant="outline" size="sm" disabled={pending} onClick={() => activate(hit)}>
                Wieder aktivieren
              </Button>
            )}
            {hit.volunteer_status === null && (
              <Button variant="outline" size="sm" disabled={pending} onClick={() => activate(hit)}>
                Ins Ehrenamtsmanagement übernehmen
              </Button>
            )}
          </>
        )}
      />
    </section>
  )
}

function ErrorMessage({ text }: { text: string }) {
  return (
    <p id="ea-person-error" role="alert" className="flex items-center gap-2 text-sm text-destructive">
      <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
      {text}
    </p>
  )
}
