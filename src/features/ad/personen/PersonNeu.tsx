import { useRef, useState, type FormEvent } from 'react'
import { ChevronLeftIcon, CircleAlertIcon } from 'lucide-react'
import { Link, useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { checkLoginEmail, createPerson, findSimilarPersons } from '@/features/ad/personen/data'
import { DublettenDialog, type SimilarPerson } from '@/features/shared/DublettenDialog'
import { MESSAGES, toMessage } from '@/lib/errors'

// T074 (US-AD-07, US-AD-24, US-AD-25): Person anlegen mit Rufname, optionaler Login-Adresse und Dublettenprüfung.
export function PersonNeu() {
  const navigate = useNavigate()
  const [first, setFirst] = useState('')
  const [preferred, setPreferred] = useState('')
  const [last, setLast] = useState('')
  const [email, setEmail] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [hits, setHits] = useState<SimilarPerson[] | null>(null)
  const [pending, setPending] = useState(false)
  const firstRef = useRef<HTMLInputElement>(null)

  const nameMissing = error === MESSAGES.nameRequired
  const emailError = error === MESSAGES.emailDomain || error === MESSAGES.emailTaken

  async function create() {
    setPending(true)
    setError(null)
    try {
      const result = await createPerson({ first, preferred, last, email })
      if (result.error) {
        const text = toMessage(result.error).text
        // Person ist angelegt, nur der Zugang fehlt: zur Person wechseln, dort lässt sich die Adresse korrigieren
        if (result.id) navigate(`/ad/personen/${result.id}`, { replace: true, state: { error: text } })
        else setError(text)
        setHits(null)
        return
      }
      navigate(`/ad/personen/${result.id}`, { replace: true })
    } catch (caught) {
      setError(toMessage(caught).text)
      setHits(null)
    } finally {
      setPending(false)
    }
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!first.trim() || !last.trim()) {
      setError(MESSAGES.nameRequired)
      firstRef.current?.focus()
      return
    }
    setPending(true)
    setError(null)
    try {
      // R1 und R2 vor der Dublettenprüfung, damit keine Person ohne Zugang stehen bleibt (AK5)
      if (email.trim()) {
        const allowed = await checkLoginEmail(email)
        if (allowed === null) return setError(MESSAGES.unexpected)
        if (!allowed) return setError(MESSAGES.emailDomain)
      }
      const similar = await findSimilarPersons(first, last, email)
      if (similar.error) {
        setError(toMessage(similar.error).text)
        return
      }
      if (similar.hits.length > 0) {
        setHits(similar.hits)
        return
      }
    } catch (caught) {
      setError(toMessage(caught).text)
      return
    } finally {
      setPending(false)
    }
    await create()
  }

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <Link
          to="/ad"
          className="inline-flex items-center gap-1 self-start rounded-md text-sm text-muted-foreground underline-offset-4 outline-none hover:text-foreground hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring focus-visible:outline-solid"
        >
          <ChevronLeftIcon aria-hidden="true" className="size-4" />
          Personen
        </Link>
        <h1 className="text-xl font-semibold">Person anlegen</h1>
      </div>

      <form className="flex max-w-md flex-col gap-6" onSubmit={onSubmit} noValidate>
        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="person-first">Vorname</Label>
            <Input
              id="person-first"
              ref={firstRef}
              required
              value={first}
              onChange={(event) => setFirst(event.target.value)}
              aria-invalid={nameMissing || undefined}
              aria-describedby={nameMissing ? 'person-error' : undefined}
              autoComplete="off"
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="person-preferred">
              Rufname <span className="font-normal text-muted-foreground">(optional)</span>
            </Label>
            <Input id="person-preferred" value={preferred} onChange={(event) => setPreferred(event.target.value)} autoComplete="off" />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="person-last">Nachname</Label>
            <Input
              id="person-last"
              required
              value={last}
              onChange={(event) => setLast(event.target.value)}
              aria-invalid={nameMissing || undefined}
              aria-describedby={nameMissing ? 'person-error' : undefined}
              autoComplete="off"
            />
          </div>
          {nameMissing && <ErrorMessage text={error!} />}
          <div className="flex flex-col gap-2">
            <Label htmlFor="person-email">
              Login-Adresse <span className="font-normal text-muted-foreground">(optional, @dav-leipzig.de)</span>
            </Label>
            <Input
              id="person-email"
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              aria-invalid={emailError || undefined}
              aria-describedby={emailError ? 'person-error' : undefined}
              autoComplete="off"
            />
            {emailError && <ErrorMessage text={error!} />}
          </div>
        </div>

        {error && !nameMissing && !emailError && <ErrorMessage text={error} />}

        <div className="flex flex-wrap gap-3">
          <Button type="submit" disabled={pending}>
            {pending ? 'Speichern …' : 'Speichern'}
          </Button>
          <Button variant="outline" asChild>
            <Link to="/ad">Abbrechen</Link>
          </Button>
        </div>
      </form>

      <DublettenDialog
        open={hits !== null}
        hits={hits ?? []}
        pending={pending}
        onCreateAnyway={create}
        onCancel={() => setHits(null)}
        hitAction={(hit) =>
          // In AD nur bei sichtbaren Treffern (R40); der Admin sieht alle Personen (v0.7.1)
          hit.is_visible ? (
            <Button variant="outline" size="sm" asChild>
              <Link to={`/ad/personen/${hit.person_id}`}>Vorhandene Person öffnen</Link>
            </Button>
          ) : null
        }
      />
    </section>
  )
}

function ErrorMessage({ text }: { text: string }) {
  return (
    <p id="person-error" role="alert" className="flex items-center gap-2 text-sm text-destructive">
      <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
      {text}
    </p>
  )
}
