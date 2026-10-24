import { useState, type ComponentProps, type ReactNode } from 'react'
import { PlusIcon } from 'lucide-react'
import { useRevalidator } from 'react-router-dom'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { CATEGORIES, CATEGORY_LABELS, type Category, type PropertyField } from '@/features/ad/eigenschaftsarten/data'
import { Section } from '@/features/ad/personen/Section'
import {
  saveProperty,
  type PersonProperty,
  type PropertiesData,
  type PropertyTypeWithFields,
} from '@/features/ad/personen/data'
import { qualificationLabel, type QualificationType } from '@/features/ad/qualifikationsarten/data'
import { Eigenschaftsformular, type FieldValues, type PropertyInput } from '@/features/shared/Eigenschaftsformular'
import { MESSAGES } from '@/lib/errors'
import { formatDate, formatDateTime } from '@/lib/format'

// T083 (US-AD-13, US-AD-19, US-AD-22): Eigenschaften nach Kategorie; aktuelle oben, beendete als „beendet“;
// Historie je Eigenschaft aufklappbar; Hinzufügen, Ändern und Beenden über das Eigenschaftsformular.
// T037: Unter /ea mit module = 'EA' – Kategorien in der Reihenfolge des Enums (US-EA-04 AK1), Gruppen-Bezug nur lesen
// (AK6) und renderExtra für Ablauf-Badge und zusätzliche Aktionen. Unter /ad unverändert.
type Props = {
  personId: string
  data: PropertiesData
  canEdit: boolean
  module?: 'AD' | 'EA'
  renderExtra?: (property: PersonProperty, type: PropertyTypeWithFields) => ReactNode
  /** T042: zusätzliche Aktionen je Eigenschaft, z. B. „Verlängern“ (EA) */
  renderActions?: (property: PersonProperty, type: PropertyTypeWithFields) => ReactNode
  /** T042: Schreibrecht je Eigenschaft (ea_property_writable); ohne die Prop gilt canEdit */
  isWritable?: (property: PersonProperty) => boolean
  /** T042: Arten, die „Eigenschaft hinzufügen“ anbietet; ohne die Prop alle */
  addableTypeIds?: string[]
  /** Nur diese Referate im Bezug wählbar (Reichweite Referat, R41) */
  restrictReferate?: string[] | null
  /** T043: Vorbelegung „gültig bis“ (EA R5) */
  onDerive?: ComponentProps<typeof Eigenschaftsformular>['onDerive']
}

const today = () => new Date().toISOString().slice(0, 10)

export function EigenschaftenAbschnitt({
  personId,
  data,
  canEdit,
  module = 'AD',
  renderExtra,
  renderActions,
  isWritable,
  addableTypeIds,
  restrictReferate = null,
  onDerive,
}: Props) {
  const revalidator = useRevalidator()
  const [adding, setAdding] = useState(false)
  const [newTypeId, setNewTypeId] = useState('')
  const [editing, setEditing] = useState<{ property: PersonProperty; endOnly: boolean } | null>(null)

  const typeById = new Map(data.types.map((t) => [t.id, t]))

  const groups = new Map<Category, PersonProperty[]>()
  for (const p of data.properties) {
    const t = typeById.get(p.property_type_id)
    if (!t) continue
    groups.set(t.category, [...(groups.get(t.category) ?? []), p])
  }
  const order = (p: PersonProperty) => (isEnded(p) ? 1 : 0)
  const categoryOrder = ([a]: [Category, unknown], [b]: [Category, unknown]) =>
    module === 'EA'
      ? CATEGORIES.indexOf(a) - CATEGORIES.indexOf(b)
      : CATEGORY_LABELS[a].localeCompare(CATEGORY_LABELS[b], 'de')

  async function submit(property: PersonProperty | null, typeId: string, input: PropertyInput) {
    const err = await saveProperty(property?.id ?? null, personId, typeId, input)
    if (err) return err
    setAdding(false)
    setEditing(null)
    revalidator.revalidate()
    return null
  }

  const newType = newTypeId ? typeById.get(newTypeId) : undefined
  const addableTypes = addableTypeIds ? data.types.filter((t) => addableTypeIds.includes(t.id)) : data.types
  const writable = (p: PersonProperty) => (isWritable ? isWritable(p) : canEdit)

  return (
    <Section id="eigenschaften" title="Eigenschaften">
      {data.properties.length === 0 && !adding && <p className="text-sm text-muted-foreground">Noch keine Eigenschaften.</p>}

      {[...groups.entries()]
        .sort(categoryOrder)
        .map(([category, props]) => (
          <div key={category} className="flex flex-col gap-2">
            <h3 className="text-sm font-medium text-muted-foreground">{CATEGORY_LABELS[category]}</h3>
            <ul className="flex flex-col divide-y rounded-xl border">
              {[...props].sort((a, b) => order(a) - order(b) || b.valid_from.localeCompare(a.valid_from)).map((p) => {
                const t = typeById.get(p.property_type_id)!
                return editing?.property.id === p.id ? (
                  <li key={p.id} className="p-3">
                    <Eigenschaftsformular
                      type={t}
                      referate={data.referate}
                      gremien={data.gremien}
                      qualificationTypes={data.qualificationTypes}
                      restrictReferate={restrictReferate}
                      onDerive={onDerive}
                      initial={{
                        field_values: p.field_values,
                        related_referat_id: p.related_referat_id,
                        related_gremium_id: p.related_gremium_id,
                        valid_from: p.valid_from,
                        valid_to: editing.endOnly ? (p.valid_to ?? today()) : p.valid_to,
                      }}
                      onSubmit={(input) => submit(p, t.id, input)}
                      onCancel={() => setEditing(null)}
                      submitLabel={editing.endOnly ? 'Beenden' : 'Speichern'}
                    />
                  </li>
                ) : (
                  <li key={p.id} className="flex flex-col gap-2 px-4 py-3">
                    <PropertyView property={p} type={t} data={data} extra={renderExtra?.(p, t)} />
                    {module === 'EA' && t.relation_kind === 'group' && (
                      <p className="text-sm text-muted-foreground">{MESSAGES.groupRelationOnlyGr}</p>
                    )}
                    {writable(p) && !(module === 'EA' && t.relation_kind === 'group') && (
                      <div className="flex flex-wrap gap-2">
                        <Button variant="outline" size="sm" onClick={() => setEditing({ property: p, endOnly: false })}>
                          Ändern
                        </Button>
                        {!isEnded(p) && (
                          <Button variant="outline" size="sm" onClick={() => setEditing({ property: p, endOnly: true })}>
                            Beenden
                          </Button>
                        )}
                        {renderActions?.(p, t)}
                      </div>
                    )}
                  </li>
                )
              })}
            </ul>
          </div>
        ))}

      {canEdit && addableTypes.length > 0 && !adding && (
        <Button variant="outline" className="self-start" onClick={() => setAdding(true)}>
          <PlusIcon data-icon="inline-start" aria-hidden="true" />
          Eigenschaft hinzufügen
        </Button>
      )}

      {adding && (
        <div className="flex flex-col gap-3">
          <div className="flex max-w-md flex-col gap-2">
            <Label htmlFor="new-property-type">Eigenschaftsart</Label>
            <select
              id="new-property-type"
              value={newTypeId}
              onChange={(e) => setNewTypeId(e.target.value)}
              className="h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm"
            >
              <option value="">– bitte wählen –</option>
              {addableTypes.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name} ({CATEGORY_LABELS[t.category]})
                </option>
              ))}
            </select>
          </div>
          {newType ? (
            <Eigenschaftsformular
              key={newType.id}
              type={newType}
              referate={data.referate}
              gremien={data.gremien}
              qualificationTypes={data.qualificationTypes}
              restrictReferate={restrictReferate}
              onDerive={onDerive}
              onSubmit={(input) => submit(null, newType.id, input)}
              onCancel={() => {
                setAdding(false)
                setNewTypeId('')
              }}
            />
          ) : (
            <Button variant="outline" className="self-start" onClick={() => setAdding(false)}>
              Abbrechen
            </Button>
          )}
        </div>
      )}
    </Section>
  )
}

function isEnded(p: PersonProperty) {
  return !!p.valid_to && p.valid_to < today()
}

function formatValue(field: PropertyField, value: FieldValues[string] | undefined, qualificationTypes: QualificationType[]) {
  if (value === undefined || value === null || value === '') return null
  switch (field.data_type) {
    case 'boolean':
      return value ? 'ja' : 'nein'
    case 'date':
      return formatDate(String(value))
    case 'number':
      return Number(value).toLocaleString('de-DE')
    case 'qualification_type': {
      const q = qualificationTypes.find((x) => x.id === value)
      return q ? qualificationLabel(q) : String(value)
    }
    default:
      return String(value)
  }
}

function Values({ fields, values, qualificationTypes }: { fields: PropertyField[]; values: FieldValues; qualificationTypes: QualificationType[] }) {
  const items = fields.map((f) => [f.label, formatValue(f, values[f.key], qualificationTypes)] as const).filter(([, v]) => v !== null)
  if (items.length === 0) return <span className="text-sm text-muted-foreground">–</span>
  return (
    <dl className="flex flex-wrap gap-x-4 gap-y-1 text-sm">
      {items.map(([label, value]) => (
        <div key={label} className="flex gap-1">
          <dt className="text-muted-foreground">{label}:</dt>
          <dd>{value}</dd>
        </div>
      ))}
    </dl>
  )
}

function Validity({ type, from, to }: { type: PropertyTypeWithFields; from: string; to: string | null }) {
  return (
    <span className="text-sm text-muted-foreground">
      {type.valid_from_label ?? 'gültig von'} {formatDate(from)}
      {to && (
        <>
          {' · '}
          {type.valid_to_label ?? 'gültig bis'} {formatDate(to)}
        </>
      )}
    </span>
  )
}

function Relation({ p, data }: { p: PersonProperty; data: PropertiesData }) {
  if (p.related_referat_id) {
    const r = data.referate.find((x) => x.id === p.related_referat_id)
    return <span className="text-sm">Referat {r?.name ?? '–'}</span>
  }
  if (p.related_gremium_id) {
    const g = data.gremien.find((x) => x.id === p.related_gremium_id)
    return <span className="text-sm">Gremium {g?.name ?? '–'}</span>
  }
  if (p.related_group_id) {
    const g = data.groups.find((x) => x.id === p.related_group_id)
    return <span className="text-sm">Gruppe {g?.name ?? '–'}</span>
  }
  return null
}

type PropertyViewProps = { property: PersonProperty; type: PropertyTypeWithFields; data: PropertiesData; extra?: ReactNode }

function PropertyView({ property: p, type: t, data, extra }: PropertyViewProps) {
  const history = [...(p.ea_property_history ?? [])].sort((a, b) => b.changed_at.localeCompare(a.changed_at))
  return (
    <div className="flex flex-col gap-1">
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-medium">{t.name}</span>
        {isEnded(p) && (
          <Badge variant="outline" className="bg-status-none-bg text-status-none">
            beendet
          </Badge>
        )}
        {extra}
      </div>
      <Values fields={t.fields} values={p.field_values} qualificationTypes={data.qualificationTypes} />
      <div className="flex flex-wrap gap-x-4 gap-y-1">
        <Relation p={p} data={data} />
        <Validity type={t} from={p.valid_from} to={p.valid_to} />
      </div>
      <span className="text-xs text-muted-foreground">
        geändert am {formatDateTime(p.updated_at)}
        {data.userNames[p.updated_by ?? ''] && ` von ${data.userNames[p.updated_by!]}`}
      </span>
      {history.length > 0 && (
        <details className="text-sm">
          <summary className="cursor-pointer text-muted-foreground">
            Historie ({history.length} {history.length === 1 ? 'frühere Fassung' : 'frühere Fassungen'})
          </summary>
          <ol className="mt-2 flex flex-col gap-2 border-l-2 pl-3">
            {history.map((h) => (
              <li key={h.id} className="flex flex-col gap-0.5">
                <Values fields={t.fields} values={h.field_values} qualificationTypes={data.qualificationTypes} />
                <Validity type={t} from={h.valid_from} to={h.valid_to} />
                <span className="text-xs text-muted-foreground">
                  abgelöst am {formatDateTime(h.changed_at)}
                  {data.userNames[h.changed_by ?? ''] && ` von ${data.userNames[h.changed_by!]}`}
                </span>
              </li>
            ))}
          </ol>
        </details>
      )}
    </div>
  )
}
