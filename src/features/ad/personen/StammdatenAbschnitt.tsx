import { useState, type FormEvent } from 'react'
import { CircleAlertIcon } from 'lucide-react'
import { useRevalidator } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Section } from '@/features/ad/personen/Section'
import { updatePersonName, VOLUNTEER_STATUS_LABELS, type PersonRow } from '@/features/ad/personen/data'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDate } from '@/lib/format'

// T075 (US-AD-24 AK1, AK3): Vorname, Rufname, Nachname bearbeitbar; Art und Ehrenamtsstatus nur lesen.
export function StammdatenAbschnitt({ person, canEdit }: { person: PersonRow; canEdit: boolean }) {
  const [editing, setEditing] = useState(false)

  return (
    <Section id="stammdaten" title="Stammdaten">
      {editing ? (
        <StammdatenForm person={person} onDone={() => setEditing(false)} />
      ) : (
        <>
          <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
            <dt className="text-muted-foreground">Vorname</dt>
            <dd>{person.first_name}</dd>
            <dt className="text-muted-foreground">Rufname</dt>
            <dd>{person.preferred_name ?? <span className="text-muted-foreground">–</span>}</dd>
            <dt className="text-muted-foreground">Nachname</dt>
            <dd>{person.last_name}</dd>
            <dt className="text-muted-foreground">Art</dt>
            <dd>{person.kind === 'function' ? 'Funktionsperson' : 'Mensch'}</dd>
            <dt className="text-muted-foreground">Ehrenamtsstatus</dt>
            <dd>
              {person.volunteer_status ? (
                <>
                  {VOLUNTEER_STATUS_LABELS[person.volunteer_status]}
                  {person.volunteer_status_since && (
                    <span className="text-muted-foreground"> seit {formatDate(person.volunteer_status_since)}</span>
                  )}
                </>
              ) : (
                <span className="text-muted-foreground">– (wird im Ehrenamtsmanagement gepflegt)</span>
              )}
            </dd>
          </dl>
          {canEdit && (
            <Button variant="outline" className="self-start" onClick={() => setEditing(true)}>
              Stammdaten bearbeiten
            </Button>
          )}
        </>
      )}
    </Section>
  )
}

function StammdatenForm({ person, onDone }: { person: PersonRow; onDone: () => void }) {
  const revalidator = useRevalidator()
  const [first, setFirst] = useState(person.first_name)
  const [preferred, setPreferred] = useState(person.preferred_name ?? '')
  const [last, setLast] = useState(person.last_name)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!first.trim() || !last.trim()) {
      setError(MESSAGES.nameRequired)
      return
    }
    setPending(true)
    setError(null)
    const err = await updatePersonName(person.person_id, { first, preferred, last })
    setPending(false)
    if (err) {
      setError(toMessage(err).text)
      return
    }
    revalidator.revalidate()
    onDone()
  }

  return (
    <form className="flex max-w-md flex-col gap-4" onSubmit={onSubmit} noValidate>
      <div className="flex flex-col gap-2">
        <Label htmlFor="stammdaten-first">Vorname</Label>
        <Input id="stammdaten-first" value={first} onChange={(e) => setFirst(e.target.value)} required autoComplete="off" />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="stammdaten-preferred">
          Rufname <span className="font-normal text-muted-foreground">(optional)</span>
        </Label>
        <Input id="stammdaten-preferred" value={preferred} onChange={(e) => setPreferred(e.target.value)} autoComplete="off" />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="stammdaten-last">Nachname</Label>
        <Input id="stammdaten-last" value={last} onChange={(e) => setLast(e.target.value)} required autoComplete="off" />
      </div>
      {error && (
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {error}
        </p>
      )}
      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={pending}>
          {pending ? 'Speichern …' : 'Speichern'}
        </Button>
        <Button type="button" variant="outline" onClick={onDone} disabled={pending}>
          Abbrechen
        </Button>
      </div>
    </form>
  )
}
