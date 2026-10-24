import { selectClassName } from '@/features/gr/shared/ui'
import type { Location } from '@/features/ez/shared/locations'

type Props = {
  id: string
  locations: Location[]
  value: string
  onChange: (value: string) => void
  invalid?: boolean
}

// Komponente „Auswahlfeld Ort“ (spec.md EZ 6, AD T120). Vorläufig in der Anwesenheitserfassung (plan.md O2):
// nur aktive Orte wählbar; ein gespeicherter, inzwischen inaktiver Ort bleibt angezeigt (R12).
export function OrtAuswahl({ id, locations, value, onChange, invalid }: Props) {
  const options = locations.filter((l) => l.is_active || l.id === value)
  return (
    <select
      id={id}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      aria-invalid={invalid || undefined}
      className={selectClassName}
    >
      <option value="">Ort wählen</option>
      {options.map((l) => (
        <option key={l.id} value={l.id}>
          {l.is_active ? l.name : `${l.name} (nicht mehr aktiv)`}
        </option>
      ))}
    </select>
  )
}
