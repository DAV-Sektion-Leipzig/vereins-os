import { useEffect, useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { findSimilarPersons } from '@/features/ad/personen/data'
import { searchPersons, EMPTY_PERSON, type NewPerson, type PersonCore } from '@/features/gr/personen/data'
import { toPayload, type PersonChoice } from '@/features/gr/personen/fields'
import { PersonFelder } from '@/features/gr/personen/PersonFelder'
import { FormError } from '@/features/gr/shared/ui'
import { DublettenDialog, type SimilarPerson } from '@/features/shared/DublettenDialog'
import { MESSAGES } from '@/lib/errors'
import { personName } from '@/lib/format'

type Field = keyof NewPerson

/**
 * Vorhandene Person suchen oder neue anlegen (spec.md 6, US-GR-06, US-GR-07, US-GR-09). Bei einer neuen Person
 * prüft die Datenbank vorher auf Dubletten (R3/R40 AD); „Vorhandene Person übernehmen“ geht auch für nicht
 * sichtbare Treffer, die Übernahme macht sie im Pfad GR sichtbar (Ü2).
 */
export function PersonWahl({
  idPrefix,
  fields,
  required,
  allowNew = true,
  validate,
  submitLabel,
  onChoose,
  onCancel,
  exclude = [],
}: {
  idPrefix: string
  fields: Field[]
  required: Field[]
  allowNew?: boolean
  /** Prüfung vor dem Speichern; Rückgabe: Meldung oder null */
  validate?: (value: NewPerson) => string | null
  submitLabel: string
  /** Speichern; Rückgabe: Fehlermeldung oder null */
  onChoose: (choice: PersonChoice) => Promise<string | null>
  onCancel?: () => void
  exclude?: string[]
}) {
  const [mode, setMode] = useState<'search' | 'new'>('search')
  const [term, setTerm] = useState('')
  const [results, setResults] = useState<PersonCore[]>([])
  const [value, setValue] = useState<NewPerson>(EMPTY_PERSON)
  const [hits, setHits] = useState<SimilarPerson[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  useEffect(() => {
    if (mode !== 'search') return
    const timer = window.setTimeout(() => {
      void searchPersons(term).then((r) => setResults((r ?? []).filter((p) => !exclude.includes(p.id))))
    }, 300)
    return () => window.clearTimeout(timer)
    // exclude ändert sich nur mit neuen Daten
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [term, mode])

  async function choose(choice: PersonChoice) {
    setPending(true)
    setError(null)
    const err = await onChoose(choice)
    setPending(false)
    if (err) setError(err)
    else {
      setHits(null)
      setValue(EMPTY_PERSON)
      setTerm('')
    }
  }

  async function onSubmitNew(event: FormEvent) {
    event.preventDefault()
    setError(null)
    if (required.some((f) => value[f].trim() === '')) return setError(validate?.(value) ?? MESSAGES.nameRequired)
    const invalid = validate?.(value)
    if (invalid) return setError(invalid)
    setPending(true)
    const similar = await findSimilarPersons(value.first_name, value.last_name, value.email)
    setPending(false)
    if (similar.error) return setError(MESSAGES.unexpected)
    if (similar.hits.length > 0) return setHits(similar.hits)
    await choose({ newPerson: toPayload(value, fields) })
  }

  return (
    <div className="flex flex-col gap-4">
      {allowNew && (
        <div role="group" aria-label="Person" className="flex flex-wrap gap-1">
          <Button type="button" variant={mode === 'search' ? 'secondary' : 'ghost'} aria-pressed={mode === 'search'} onClick={() => setMode('search')}>
            Vorhandene Person
          </Button>
          <Button type="button" variant={mode === 'new' ? 'secondary' : 'ghost'} aria-pressed={mode === 'new'} onClick={() => setMode('new')}>
            Neue Person
          </Button>
        </div>
      )}

      {mode === 'search' ? (
        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-2 sm:max-w-xs">
            <Label htmlFor={`${idPrefix}-search`}>Name suchen</Label>
            <Input id={`${idPrefix}-search`} type="search" value={term} onChange={(e) => setTerm(e.target.value)} autoComplete="off" />
          </div>
          {term.trim().length >= 2 && results.length === 0 && <p className="text-sm text-muted-foreground">Keine Person gefunden.</p>}
          {results.length > 0 && (
            <ul className="flex flex-col divide-y rounded-xl border">
              {results.map((p) => (
                <li key={p.id} className="flex items-center justify-between gap-2 px-3 py-2">
                  <span>{personName(p)}</span>
                  <Button type="button" variant="outline" onClick={() => void choose({ personId: p.id })} disabled={pending} className="h-11 sm:h-8">
                    {submitLabel}
                  </Button>
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : (
        <form onSubmit={onSubmitNew} noValidate className="flex flex-col gap-4">
          <PersonFelder idPrefix={idPrefix} value={value} onChange={setValue} fields={fields} required={required} />
          <Button type="submit" disabled={pending} className="h-11 self-start sm:h-8">
            {pending ? 'Speichern …' : submitLabel}
          </Button>
        </form>
      )}

      <FormError text={error} />
      {onCancel && (
        <Button type="button" variant="ghost" onClick={onCancel} disabled={pending} className="self-start">
          Abbrechen
        </Button>
      )}

      <DublettenDialog
        open={hits !== null}
        hits={hits ?? []}
        pending={pending}
        onCancel={() => setHits(null)}
        onCreateAnyway={() => void choose({ newPerson: toPayload(value, fields) })}
        hitAction={(hit) => (
          <Button type="button" variant="outline" size="sm" onClick={() => void choose({ personId: hit.person_id })} disabled={pending}>
            Vorhandene Person übernehmen
          </Button>
        )}
      />
    </div>
  )
}
