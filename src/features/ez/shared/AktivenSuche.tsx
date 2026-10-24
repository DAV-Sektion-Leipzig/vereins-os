import { useEffect, useId, useState } from 'react'
import { UserPlusIcon } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EZ_MESSAGES } from '@/features/ez/errors'
import { personName } from '@/lib/format'
import { supabase } from '@/lib/supabase'

export type ActivePerson = { id: string; first_name: string; preferred_name: string | null; last_name: string }

type Props = {
  label: string
  /** Vor der Eingabe angezeigt, z. B. Gruppenleitung, Trainer:innen und Helfer:innen der Gruppe („Aus der Gruppe“, R11). */
  suggestions?: ActivePerson[]
  suggestionsTitle?: string
  /** Bereits eingetragene Personen; erscheinen nicht in der Auswahl (R17). */
  excludeIds?: string[]
  onSelect: (person: ActivePerson) => void
}

const SEARCH_DELAY_MS = 300

// Komponente „Personensuche Aktive“ (spec.md EZ 6, AD T120). Vorläufig in der Anwesenheitserfassung (plan.md O2):
// Suche über ea_search_active_persons ab 2 Zeichen (nur Ehrenamtsstatus „aktiv“), Auswahl per Schaltfläche.
export function AktivenSuche({ label, suggestions = [], suggestionsTitle = 'Aus der Gruppe', excludeIds = [], onSelect }: Props) {
  const inputId = useId()
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<ActivePerson[] | null>(null)
  const [failed, setFailed] = useState(false)
  const trimmed = query.trim()

  useEffect(() => {
    if (trimmed.length < 2) return
    let cancelled = false
    const timer = window.setTimeout(async () => {
      const { data, error } = await supabase.rpc('ea_search_active_persons', { p_query: trimmed, p_limit: 20 })
      if (cancelled) return
      setFailed(!!error)
      setResults(error || !Array.isArray(data) ? [] : (data as ActivePerson[]))
    }, SEARCH_DELAY_MS)
    return () => {
      cancelled = true
      window.clearTimeout(timer)
    }
  }, [trimmed])

  const exclude = new Set(excludeIds)
  const shownSuggestions = suggestions.filter((p) => !exclude.has(p.id))
  const shownResults = trimmed.length >= 2 ? (results ?? []).filter((p) => !exclude.has(p.id)) : []

  function choose(person: ActivePerson) {
    onSelect(person)
    setQuery('')
    setResults(null)
  }

  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-col gap-2">
        <Label htmlFor={inputId}>{label}</Label>
        <Input
          id={inputId}
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Name eingeben (mind. 2 Zeichen)"
          autoComplete="off"
        />
      </div>
      {trimmed.length < 2 && shownSuggestions.length > 0 && (
        <PersonList title={suggestionsTitle} persons={shownSuggestions} onChoose={choose} />
      )}
      {trimmed.length >= 2 && results !== null && (
        <>
          {failed && <p className="text-sm text-destructive">Die Suche ist fehlgeschlagen. Bitte versuche es erneut.</p>}
          {!failed && shownResults.length === 0 && <p className="text-sm text-muted-foreground">{EZ_MESSAGES.noActivePerson}</p>}
          {shownResults.length > 0 && <PersonList title="Alle Aktiven" persons={shownResults} onChoose={choose} />}
        </>
      )}
    </div>
  )
}

function PersonList({ title, persons, onChoose }: { title: string; persons: ActivePerson[]; onChoose: (p: ActivePerson) => void }) {
  return (
    <div className="flex flex-col gap-1.5">
      <span className="text-sm font-medium text-muted-foreground">{title}</span>
      <ul className="flex max-h-64 flex-col divide-y overflow-y-auto rounded-xl border">
        {persons.map((p) => (
          <li key={p.id}>
            <button
              type="button"
              onClick={() => onChoose(p)}
              className="flex min-h-11 w-full items-center gap-2 px-3 text-left text-sm outline-none hover:bg-muted focus-visible:bg-muted"
            >
              <UserPlusIcon aria-hidden="true" className="size-4 shrink-0 text-muted-foreground" />
              {personName(p)}
            </button>
          </li>
        ))}
      </ul>
    </div>
  )
}
