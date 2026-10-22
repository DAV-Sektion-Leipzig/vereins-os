import { useId, useMemo, useState } from 'react'
import { Input } from '@/components/ui/input'
import {
  KIND_LABELS,
  qualificationLabel,
  type QualificationKind,
  type QualificationType,
} from '@/features/ad/qualifikationsarten/data'
import { cn } from '@/lib/utils'

// T076 (US-AD-19 AK2): Auswahlfeld „Qualifikationsart“ – durchsuchbar nach Bezeichnung und Kürzel,
// gruppiert nach Sparte, nur Status „aktuell“ und erlaubte Typen (R25, R28).
type Option = Pick<QualificationType, 'id' | 'code' | 'name' | 'discipline' | 'kind' | 'status'>

type Props = {
  options: Option[]
  value: string | null
  onChange: (id: string | null) => void
  /** Erlaubte Typen; leer oder undefined = alle (R28). */
  allowedKinds?: QualificationKind[] | null
  label?: string
  required?: boolean
  invalid?: boolean
  describedBy?: string
  className?: string
}

export function QualifikationsartAuswahl({
  options,
  value,
  onChange,
  allowedKinds,
  label = 'Qualifikationsart',
  required,
  invalid,
  describedBy,
  className,
}: Props) {
  const id = useId()
  const [query, setQuery] = useState('')

  const selected = options.find((o) => o.id === value) ?? null
  const q = query.trim().toLowerCase()

  const groups = useMemo(() => {
    const allowed = options.filter(
      (o) =>
        (o.status === 'current' || o.id === value) &&
        (!allowedKinds || allowedKinds.length === 0 || allowedKinds.includes(o.kind)),
    )
    const hits = q
      ? allowed.filter((o) => o.name.toLowerCase().includes(q) || (o.code ?? '').toLowerCase().includes(q))
      : allowed
    const byDiscipline = new Map<string, Option[]>()
    for (const o of hits) {
      const list = byDiscipline.get(o.discipline) ?? []
      list.push(o)
      byDiscipline.set(o.discipline, list)
    }
    return [...byDiscipline.entries()].sort(([a], [b]) => a.localeCompare(b, 'de'))
  }, [options, allowedKinds, q, value])

  return (
    <div className={cn('flex flex-col gap-2', className)}>
      <label htmlFor={`${id}-select`} className="text-sm font-medium">
        {label}
        {required && <span className="sr-only"> (Pflicht)</span>}
      </label>
      <Input
        id={`${id}-search`}
        type="search"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        placeholder="Nach Bezeichnung oder Kürzel suchen"
        aria-label={`${label} durchsuchen`}
        autoComplete="off"
      />
      <select
        id={`${id}-select`}
        value={value ?? ''}
        onChange={(event) => onChange(event.target.value || null)}
        required={required}
        aria-invalid={invalid || undefined}
        aria-describedby={describedBy}
        size={Math.min(8, Math.max(3, groups.reduce((n, [, items]) => n + items.length + 1, 0)))}
        className="w-full rounded-lg border border-input bg-background px-1 py-1 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm"
      >
        {!required && <option value="">– keine –</option>}
        {groups.map(([discipline, items]) => (
          <optgroup key={discipline} label={discipline}>
            {items.map((o) => (
              <option key={o.id} value={o.id}>
                {qualificationLabel(o)} · {KIND_LABELS[o.kind]}
              </option>
            ))}
          </optgroup>
        ))}
      </select>
      {selected && (
        <p className="text-sm text-muted-foreground">
          Ausgewählt: {qualificationLabel(selected)}
        </p>
      )}
      {groups.length === 0 && <p className="text-sm text-muted-foreground">Keine Qualifikationsarten gefunden.</p>}
    </div>
  )
}
