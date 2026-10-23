// Ausscheiden nach R8 und R20 (T046): welche Eigenschaften beendet werden können und welche nur als Hinweis erscheinen.
import type { PersonProperty, PropertiesData, PropertyTypeWithFields } from '@/features/ad/personen/data'
import { formatDate } from '@/lib/format'

const END_KINDS = ['function', 'position', 'committee']

export type LeaveItem = {
  property: PersonProperty
  type: PropertyTypeWithFields
  /** zum Beenden auswählbar; sonst nur Hinweis */
  selectable: boolean
  note: string | null
}

export type LeavePlan = { items: LeaveItem[]; hints: string[] }

const isCurrent = (p: PersonProperty, today: string) => p.valid_from <= today && (!p.valid_to || p.valid_to >= today)

export function describeProperty(p: PersonProperty, t: PropertyTypeWithFields, data: PropertiesData): string {
  const value = t.system_key === 'committee' ? p.field_values.role : t.system_key ? p.field_values[t.system_key] : undefined
  const referat = data.referate.find((r) => r.id === p.related_referat_id)?.name
  const gremium = data.gremien.find((g) => g.id === p.related_gremium_id)?.name
  const relation = referat ?? gremium
  return [t.name, value, relation && `(${relation})`].filter(Boolean).join(' ')
}

/** Zusammenstellung nach R8 und R20: auswählbar nur, was schreibbar ist und spätestens am Austrittsdatum beginnt. */
export function buildLeavePlan(data: PropertiesData, writable: Record<string, boolean>, leaveDate: string): LeavePlan {
  const today = new Date().toISOString().slice(0, 10)
  const typeById = new Map(data.types.map((t) => [t.id, t]))
  const items: LeaveItem[] = []
  const hints: string[] = []

  for (const p of data.properties) {
    const t = typeById.get(p.property_type_id)
    if (!t?.system_key || !isCurrent(p, today)) continue

    if (END_KINDS.includes(t.system_key)) {
      if (t.relation_kind === 'group') items.push({ property: p, type: t, selectable: false, note: 'im Modul Gruppen beenden' })
      else if (!writable[p.id]) items.push({ property: p, type: t, selectable: false, note: 'wird nicht beendet (anderes Referat)' })
      else if (p.valid_from > leaveDate)
        items.push({ property: p, type: t, selectable: false, note: `beginnt erst am ${formatDate(p.valid_from)}` })
      else items.push({ property: p, type: t, selectable: true, note: null })
    } else if (t.system_key === 'issued_item') {
      hints.push(`${p.field_values.item ?? t.name} – nicht zurückgegeben`)
    } else if (t.system_key === 'external_access') {
      hints.push(`${[t.name, p.field_values.system].filter(Boolean).join(' ')} – läuft`)
    }
  }
  return { items, hints }
}
