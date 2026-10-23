import type { PropertiesData } from '@/features/ad/personen/data'
import { describeProperty, type LeavePlan } from '@/features/ea/aktive/ausscheiden'
import { formatDate } from '@/lib/format'

// T046 (US-EA-09, R8): zweiter Schritt bei „ausgeschieden“. Aktuelle Funktionen, Ämter und Gremien, die der Nutzer
// ändern darf, sind zum Beenden vorausgewählt (abwählbar); übrige erscheinen als Hinweis.

type Props = {
  plan: LeavePlan
  data: PropertiesData
  selected: string[]
  onToggle: (propertyId: string, checked: boolean) => void
  leaveDate: string
}

export function AusscheidenSchritt({ plan, data, selected, onToggle, leaveDate }: Props) {
  return (
    <div className="flex flex-col gap-4">
      {plan.items.length > 0 ? (
        <fieldset className="flex flex-col gap-2">
          <legend className="mb-2 text-sm font-medium">Zum {formatDate(leaveDate)} beenden</legend>
          <ul className="flex flex-col gap-2">
            {plan.items.map(({ property: p, type: t, selectable, note }) => (
              <li key={p.id}>
                {selectable ? (
                  <label className="flex items-start gap-2 text-sm">
                    <input
                      type="checkbox"
                      checked={selected.includes(p.id)}
                      onChange={(e) => onToggle(p.id, e.target.checked)}
                      className="mt-0.5 size-4 accent-primary"
                    />
                    {describeProperty(p, t, data)}
                  </label>
                ) : (
                  <p className="flex flex-col text-sm">
                    <span>{describeProperty(p, t, data)}</span>
                    <span className="text-muted-foreground">{note}</span>
                  </p>
                )}
              </li>
            ))}
          </ul>
        </fieldset>
      ) : (
        <p className="text-sm text-muted-foreground">Keine laufenden Funktionen, Ämter oder Gremien.</p>
      )}

      {plan.hints.length > 0 && (
        <div className="flex flex-col gap-1 rounded-lg bg-status-locked-bg p-3 text-sm text-status-locked">
          <p className="font-medium">Bitte außerdem klären:</p>
          <ul className="list-disc pl-5">
            {plan.hints.map((h, i) => (
              <li key={i}>{h}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}
