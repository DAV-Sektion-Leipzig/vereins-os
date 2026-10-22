import { useState, type FormEvent } from 'react'
import { ArrowDownIcon, ArrowUpIcon, ChevronLeftIcon, CircleAlertIcon, PlusIcon, ShieldAlertIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  CATEGORIES,
  CATEGORY_LABELS,
  DATA_TYPE_LABELS,
  DATA_TYPES,
  READ_LEVEL_HINTS,
  READ_LEVEL_LABELS,
  READ_LEVELS,
  RELATION_LABELS,
  savePropertyType,
  suggestKey,
  type Category,
  type DataType,
  type EditResult,
  type FieldInput,
  type ReadLevel,
  type RelationKind,
  type TypeInput,
} from '@/features/ad/eigenschaftsarten/data'
import { KIND_LABELS, KINDS, type QualificationKind } from '@/features/ad/qualifikationsarten/data'
import { MESSAGES, toMessage } from '@/lib/errors'
import type { ModuleCode } from '@/lib/rights'

const ART9_HINT = 'Erfasse keine Gesundheitsdaten, Religion, politische Meinung oder andere besondere Kategorien nach Art. 9 DSGVO.'

const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:opacity-50 sm:text-sm'

// T081 (US-AD-12, US-AD-19, US-AD-22): Eigenschaftsart mit Feldern anlegen (/neu) oder ändern (/:id).
export function EigenschaftsartBearbeiten() {
  const data = useLoaderData() as EditResult

  if (data.failed) {
    return (
      <section className="flex flex-col gap-4">
        <BackLink />
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {MESSAGES.unexpected}
        </p>
      </section>
    )
  }

  return (
    <section className="flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <BackLink />
        <h1 className="flex flex-wrap items-center gap-3 text-xl font-semibold">
          {data.item?.name ?? 'Neue Eigenschaftsart'}
          {data.item?.origin === 'system' && <Badge variant="outline">System</Badge>}
        </h1>
        {data.item?.system_key && (
          <p className="text-sm text-muted-foreground">Systemschlüssel {data.item.system_key}</p>
        )}
      </div>
      {data.canEdit ? <TypeForm key={data.item?.id ?? 'neu'} data={data} /> : <ReadOnly data={data} />}
    </section>
  )
}

function BackLink() {
  return (
    <Link
      to="/ad/eigenschaftsarten"
      className="inline-flex items-center gap-1 self-start rounded-md text-sm text-muted-foreground underline-offset-4 outline-none hover:text-foreground hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring focus-visible:outline-solid"
    >
      <ChevronLeftIcon aria-hidden="true" className="size-4" />
      Eigenschaftsarten
    </Link>
  )
}

function ReadOnly({ data }: { data: EditResult }) {
  const t = data.item!
  const moduleName = (code: string) => data.modules.find((m) => m.code === code)?.name ?? code
  return (
    <div className="flex max-w-2xl flex-col gap-6">
      <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
        <dt className="text-muted-foreground">Zweck</dt>
        <dd>{t.purpose}</dd>
        <dt className="text-muted-foreground">Kategorie</dt>
        <dd>{CATEGORY_LABELS[t.category]}</dd>
        <dt className="text-muted-foreground">Lesestufe</dt>
        <dd>{READ_LEVEL_LABELS[t.read_level]}</dd>
        <dt className="text-muted-foreground">Bezug</dt>
        <dd>
          {RELATION_LABELS[t.relation_kind]}
          {t.relation_kind !== 'none' && t.relation_required && ' (Pflicht)'}
        </dd>
        <dt className="text-muted-foreground">Mehrere gültige Einträge</dt>
        <dd>{t.allow_multiple ? 'ja' : 'nein, nur ein gültiger Eintrag je Zeitraum'}</dd>
        <dt className="text-muted-foreground">Sichtbar in</dt>
        <dd>{t.visible_in.map(moduleName).join(', ')}</dd>
        <dt className="text-muted-foreground">Bezeichnung „gültig von“</dt>
        <dd>{t.valid_from_label ?? <span className="text-muted-foreground">gültig von</span>}</dd>
        <dt className="text-muted-foreground">Bezeichnung „gültig bis“</dt>
        <dd>{t.valid_to_label ?? <span className="text-muted-foreground">gültig bis</span>}</dd>
      </dl>
      <section aria-labelledby="fields-heading" className="flex flex-col gap-2">
        <h2 id="fields-heading" className="font-medium">
          Felder
        </h2>
        <ol className="divide-y rounded-xl border text-sm">
          {data.fields.map((f) => (
            <li key={f.id} className="flex flex-col gap-0.5 px-4 py-2.5">
              <span className="font-medium">
                {f.label} {f.is_required && <span className="font-normal text-muted-foreground">(Pflicht)</span>}
              </span>
              <span className="text-muted-foreground">
                {DATA_TYPE_LABELS[f.data_type]} · Schlüssel {f.key}
                {f.choice_values && ` · ${f.choice_values.join(', ')}`}
                {f.allowed_qualification_kinds && ` · nur ${f.allowed_qualification_kinds.map((k) => KIND_LABELS[k]).join(', ')}`}
              </span>
            </li>
          ))}
        </ol>
      </section>
    </div>
  )
}

type FieldRow = FieldInput & { uid: string; choiceText: string; keyTouched: boolean }

function newField(): FieldRow {
  return {
    uid: crypto.randomUUID(),
    id: null,
    key: '',
    label: '',
    data_type: 'text',
    is_required: false,
    choice_values: [],
    allowed_qualification_kinds: [],
    choiceText: '',
    keyTouched: false,
  }
}

function TypeForm({ data }: { data: EditResult }) {
  const navigate = useNavigate()
  const item = data.item
  const isNew = !item
  const [type, setType] = useState<TypeInput>({
    name: item?.name ?? '',
    purpose: item?.purpose ?? '',
    category: item?.category ?? 'other',
    read_level: item?.read_level ?? 'all',
    relation_kind: item?.relation_kind ?? 'none',
    relation_required: item?.relation_required ?? false,
    allow_multiple: item?.allow_multiple ?? true,
    visible_in: item?.visible_in ?? ['AD'],
    valid_from_label: item?.valid_from_label ?? '',
    valid_to_label: item?.valid_to_label ?? '',
  })
  const [fields, setFields] = useState<FieldRow[]>(
    data.fields.length > 0
      ? data.fields.map((f) => ({
          uid: f.id,
          id: f.id,
          key: f.key,
          label: f.label,
          data_type: f.data_type,
          is_required: f.is_required,
          choice_values: f.choice_values ?? [],
          allowed_qualification_kinds: f.allowed_qualification_kinds ?? [],
          choiceText: (f.choice_values ?? []).join('\n'),
          keyTouched: true,
        }))
      : [newField()],
  )
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  const set = <K extends keyof TypeInput>(key: K, value: TypeInput[K]) => setType((c) => ({ ...c, [key]: value }))
  const updateField = (uid: string, patch: Partial<FieldRow>) =>
    setFields((list) => list.map((f) => (f.uid === uid ? { ...f, ...patch } : f)))
  const move = (index: number, delta: number) =>
    setFields((list) => {
      const next = [...list]
      const target = index + delta
      if (target < 0 || target >= next.length) return list
      ;[next[index], next[target]] = [next[target], next[index]]
      return next
    })

  function toggleModule(code: ModuleCode, checked: boolean) {
    set('visible_in', checked ? [...new Set([...type.visible_in, code])] : type.visible_in.filter((c) => c !== code))
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    // R9 vorab im Frontend; die Datenbank prüft erneut
    if (!type.purpose.trim()) return setError(MESSAGES.purposeRequired)
    if (fields.length === 0) return setError(MESSAGES.noFields)
    if (type.visible_in.length === 0) return setError('Bitte mindestens ein Modul unter „sichtbar in“ wählen.')
    const prepared: FieldInput[] = fields.map((f) => ({
      id: f.id,
      key: f.key || suggestKey(f.label),
      label: f.label.trim(),
      data_type: f.data_type,
      is_required: f.is_required,
      choice_values: f.choiceText
        .split('\n')
        .map((v) => v.trim())
        .filter(Boolean),
      allowed_qualification_kinds: f.allowed_qualification_kinds,
    }))
    if (prepared.some((f) => !f.label || !f.key)) return setError('Bitte jedem Feld eine Bezeichnung geben.')
    if (prepared.some((f) => f.data_type === 'choice' && f.choice_values.length === 0)) return setError(MESSAGES.choiceValuesRequired)

    setPending(true)
    try {
      const result = await savePropertyType(item?.id ?? null, type, prepared)
      if (result.error) {
        setError(toMessage(result.error).text)
        return
      }
      navigate('/ad/eigenschaftsarten')
    } catch (caught) {
      setError(toMessage(caught).text)
    } finally {
      setPending(false)
    }
  }

  return (
    <form className="flex max-w-2xl flex-col gap-8" onSubmit={onSubmit} noValidate>
      {isNew && (
        <p role="note" className="flex items-start gap-2 rounded-xl border bg-muted/50 p-4 text-sm">
          <ShieldAlertIcon aria-hidden="true" className="mt-0.5 size-4 shrink-0 text-primary" />
          {ART9_HINT}
        </p>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Name" htmlFor="pt-name" className="sm:col-span-2">
          <Input id="pt-name" value={type.name} onChange={(e) => set('name', e.target.value)} required autoComplete="off" />
        </Field>
        <Field label="Zweck" hint="Pflicht, z. B. „Nachweis der Trainerlizenz“" htmlFor="pt-purpose" className="sm:col-span-2">
          <Input id="pt-purpose" value={type.purpose} onChange={(e) => set('purpose', e.target.value)} required autoComplete="off" />
        </Field>
        <Field label="Kategorie" hint="nur Anzeige" htmlFor="pt-category">
          <select id="pt-category" value={type.category} onChange={(e) => set('category', e.target.value as Category)} className={selectClassName}>
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {CATEGORY_LABELS[c]}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Bezug" htmlFor="pt-relation" hint={data.inUse ? 'gesperrt, solange Eigenschaften existieren' : undefined}>
          <select
            id="pt-relation"
            value={type.relation_kind}
            onChange={(e) => set('relation_kind', e.target.value as RelationKind)}
            disabled={data.inUse}
            className={selectClassName}
          >
            {(['none', 'referat', 'gremium', 'group'] as RelationKind[])
              .filter((r) => r !== 'group' || data.canGroup || type.relation_kind === 'group')
              .map((r) => (
                <option key={r} value={r}>
                  {RELATION_LABELS[r]}
                </option>
              ))}
          </select>
        </Field>
      </div>

      <fieldset className="flex flex-col gap-3">
        <legend className="mb-3 font-medium">Lesestufe</legend>
        {READ_LEVELS.filter((l) => l !== 'confidential' || data.canConfidential || type.read_level === 'confidential').map((level) => (
          <label key={level} className="flex cursor-pointer items-start gap-3 text-sm">
            <input
              type="radio"
              name="read_level"
              value={level}
              checked={type.read_level === level}
              onChange={() => set('read_level', level as ReadLevel)}
              disabled={level === 'confidential' && !data.canConfidential}
              className="mt-0.5 size-4 accent-primary"
            />
            <span className="flex flex-col">
              <span className="font-medium">{READ_LEVEL_LABELS[level as ReadLevel]}</span>
              <span className="text-muted-foreground">{READ_LEVEL_HINTS[level as ReadLevel]}</span>
            </span>
          </label>
        ))}
      </fieldset>

      <div className="flex flex-col gap-3">
        {type.relation_kind !== 'none' && (
          <label className="flex items-center gap-3 text-sm">
            <input
              type="checkbox"
              checked={type.relation_required}
              onChange={(e) => set('relation_required', e.target.checked)}
              className="size-4 accent-primary"
            />
            Bezug Pflicht
          </label>
        )}
        <label className="flex items-center gap-3 text-sm">
          <input type="checkbox" checked={type.allow_multiple} onChange={(e) => set('allow_multiple', e.target.checked)} className="size-4 accent-primary" />
          Mehrere gültige Einträge je Zeitraum erlaubt
        </label>
      </div>

      <fieldset className="flex flex-col gap-2">
        <legend className="mb-2 font-medium">
          Sichtbar in <span className="font-normal text-muted-foreground">(nur Anzeige, steuert nicht den Zugriff)</span>
        </legend>
        <div className="flex flex-wrap gap-x-6 gap-y-2">
          {data.modules.map((m) => (
            <label key={m.code} className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={type.visible_in.includes(m.code)}
                onChange={(e) => toggleModule(m.code, e.target.checked)}
                className="size-4 accent-primary"
              />
              {m.name}
            </label>
          ))}
        </div>
      </fieldset>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Bezeichnung für „gültig von“" hint="optional, höchstens 40 Zeichen" htmlFor="pt-from-label">
          <Input id="pt-from-label" value={type.valid_from_label} onChange={(e) => set('valid_from_label', e.target.value)} placeholder="gültig von" maxLength={40} autoComplete="off" />
        </Field>
        <Field label="Bezeichnung für „gültig bis“" hint="optional, höchstens 40 Zeichen" htmlFor="pt-to-label">
          <Input id="pt-to-label" value={type.valid_to_label} onChange={(e) => set('valid_to_label', e.target.value)} placeholder="gültig bis" maxLength={40} autoComplete="off" />
        </Field>
      </div>

      <fieldset className="flex flex-col gap-3">
        <legend className="mb-1 font-medium">Felder</legend>
        {data.inUse && (
          <p className="mb-2 text-sm text-muted-foreground">
            Es gibt Eigenschaften dieser Art: Datentypen sind gesperrt, Auswahlwerte lassen sich nur ergänzen, neue Felder nur optional.
          </p>
        )}
        <ol className="flex flex-col gap-3">
          {fields.map((f, index) => (
            <li key={f.uid} className="flex flex-col gap-4 rounded-xl border p-4">
              <div className="flex items-center justify-between gap-3">
                <span className="text-sm font-medium">Feld {index + 1}</span>
                <div className="flex gap-1">
                  <Button type="button" variant="ghost" size="icon-sm" onClick={() => move(index, -1)} disabled={index === 0} aria-label={`Feld ${index + 1} nach oben`}>
                    <ArrowUpIcon aria-hidden="true" />
                  </Button>
                  <Button type="button" variant="ghost" size="icon-sm" onClick={() => move(index, 1)} disabled={index === fields.length - 1} aria-label={`Feld ${index + 1} nach unten`}>
                    <ArrowDownIcon aria-hidden="true" />
                  </Button>
                  {!f.id && (
                    <Button type="button" variant="ghost" size="sm" onClick={() => setFields((l) => l.filter((x) => x.uid !== f.uid))}>
                      Entfernen
                    </Button>
                  )}
                </div>
              </div>
              <div className="grid gap-4 sm:grid-cols-2">
                <Field label="Bezeichnung" htmlFor={`f-${f.uid}-label`}>
                  <Input
                    id={`f-${f.uid}-label`}
                    value={f.label}
                    onChange={(e) => updateField(f.uid, { label: e.target.value, key: f.id || f.keyTouched ? f.key : suggestKey(e.target.value) })}
                    required
                    autoComplete="off"
                  />
                </Field>
                <Field label="Schlüssel" hint={f.id ? 'nach Anlage unveränderlich' : 'aus der Bezeichnung vorgeschlagen'} htmlFor={`f-${f.uid}-key`}>
                  <Input
                    id={`f-${f.uid}-key`}
                    value={f.key}
                    onChange={(e) => updateField(f.uid, { key: e.target.value, keyTouched: true })}
                    readOnly={!!f.id}
                    pattern="[a-z][a-z0-9_]{0,39}"
                    autoComplete="off"
                  />
                </Field>
                <Field label="Datentyp" htmlFor={`f-${f.uid}-type`} hint={f.id && data.inUse ? 'gesperrt' : undefined}>
                  <select
                    id={`f-${f.uid}-type`}
                    value={f.data_type}
                    onChange={(e) => updateField(f.uid, { data_type: e.target.value as DataType })}
                    disabled={!!f.id && data.inUse}
                    className={selectClassName}
                  >
                    {DATA_TYPES.map((d) => (
                      <option key={d} value={d}>
                        {DATA_TYPE_LABELS[d]}
                      </option>
                    ))}
                  </select>
                </Field>
                <label className="flex items-center gap-3 self-end pb-1.5 text-sm">
                  <input
                    type="checkbox"
                    checked={f.is_required}
                    onChange={(e) => updateField(f.uid, { is_required: e.target.checked })}
                    disabled={!f.id && data.inUse}
                    className="size-4 accent-primary"
                  />
                  Pflichtfeld
                  {!f.id && data.inUse && <span className="text-muted-foreground">(neue Felder nur optional)</span>}
                </label>
                {f.data_type === 'choice' && (
                  <Field label="Auswahlwerte" hint="ein Wert je Zeile; vorhandene Werte bleiben" htmlFor={`f-${f.uid}-choices`} className="sm:col-span-2">
                    <textarea
                      id={`f-${f.uid}-choices`}
                      value={f.choiceText}
                      onChange={(e) => updateField(f.uid, { choiceText: e.target.value })}
                      rows={4}
                      className="w-full rounded-lg border border-input bg-background px-2.5 py-1.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm"
                    />
                  </Field>
                )}
                {f.data_type === 'qualification_type' && (
                  <fieldset className="flex flex-col gap-2 sm:col-span-2">
                    <legend className="text-sm font-medium">
                      Erlaubte Typen <span className="font-normal text-muted-foreground">(keine Auswahl = alle)</span>
                    </legend>
                    <div className="flex flex-wrap gap-x-6 gap-y-2">
                      {KINDS.map((k) => (
                        <label key={k} className="flex items-center gap-2 text-sm">
                          <input
                            type="checkbox"
                            checked={f.allowed_qualification_kinds.includes(k)}
                            onChange={(e) =>
                              updateField(f.uid, {
                                allowed_qualification_kinds: e.target.checked
                                  ? [...f.allowed_qualification_kinds, k]
                                  : f.allowed_qualification_kinds.filter((x: QualificationKind) => x !== k),
                              })
                            }
                            className="size-4 accent-primary"
                          />
                          {KIND_LABELS[k]}
                        </label>
                      ))}
                    </div>
                  </fieldset>
                )}
              </div>
            </li>
          ))}
        </ol>
        <Button type="button" variant="outline" className="self-start" onClick={() => setFields((l) => [...l, newField()])}>
          <PlusIcon data-icon="inline-start" aria-hidden="true" />
          Feld hinzufügen
        </Button>
      </fieldset>

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
        <Button variant="outline" asChild>
          <Link to="/ad/eigenschaftsarten">Abbrechen</Link>
        </Button>
      </div>
    </form>
  )
}

function Field({
  label,
  hint,
  htmlFor,
  className,
  children,
}: {
  label: string
  hint?: string
  htmlFor: string
  className?: string
  children: React.ReactNode
}) {
  return (
    <div className={['flex flex-col gap-2', className].filter(Boolean).join(' ')}>
      <Label htmlFor={htmlFor}>
        {label}
        {hint && <span className="font-normal text-muted-foreground"> ({hint})</span>}
      </Label>
      {children}
    </div>
  )
}
