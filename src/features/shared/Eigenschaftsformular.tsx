import { useEffect, useId, useState, type FormEvent } from 'react'
import { CircleAlertIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { DATA_TYPE_LABELS, type PropertyField, type PropertyType } from '@/features/ad/eigenschaftsarten/data'
import type { QualificationType } from '@/features/ad/qualifikationsarten/data'
import { QualifikationsartAuswahl } from '@/features/shared/QualifikationsartAuswahl'
import { toMessage } from '@/lib/errors'

// T082 (US-AD-13, US-AD-19, US-AD-22; R35, R38, R49): Eingaben aus den Feldern der Eigenschaftsart,
// Bezug-Auswahl und gültig von/bis mit den Bezeichnungen der Art; Fehler je Feld aus dem detail der Datenbank.
export type FieldValues = Record<string, string | number | boolean>

export type PropertyInput = {
  field_values: FieldValues
  related_referat_id: string | null
  related_gremium_id: string | null
  valid_from: string
  valid_to: string | null
}

export type NamedOption = { id: string; name: string; is_active: boolean }

type Props = {
  type: PropertyType & { fields: PropertyField[] }
  referate: NamedOption[]
  gremien: NamedOption[]
  qualificationTypes: QualificationType[]
  initial?: Partial<PropertyInput>
  /** Nur diese Referate wählbar (Reichweite Referat, R41); null = alle aktiven */
  restrictReferate?: string[] | null
  onSubmit: (input: PropertyInput) => Promise<unknown>
  onCancel: () => void
  submitLabel?: string
  /**
   * Vorbelegung „gültig bis“ (EA R5, T043): wird bei Änderung von Qualifikationsart, „gültig von“ oder
   * „letzte Fortbildung“ aufgerufen, solange der Nutzer „gültig bis“ nicht selbst geändert hat.
   * Nur für Arten mit den Feldern qualification_type und valid_until; ohne die Prop keine Vorbelegung (/ad).
   */
  onDerive?: (input: { qualificationType: string; validFrom: string; lastTraining: string | null }) => Promise<string | null>
}

type Draft = Record<string, string>

function toDraft(fields: PropertyField[], values: FieldValues | undefined): Draft {
  const draft: Draft = {}
  for (const f of fields) {
    const v = values?.[f.key]
    draft[f.key] = v === undefined || v === null ? '' : String(v)
  }
  return draft
}

/** Werte je Feld nach spec.md Abschnitt 2 (Text als String, Zahl/Jahr als Zahl, Ja/Nein als boolean, Datum als YYYY-MM-DD). */
function toFieldValues(fields: PropertyField[], draft: Draft): FieldValues {
  const out: FieldValues = {}
  for (const f of fields) {
    const raw = (draft[f.key] ?? '').trim()
    if (raw === '') continue
    switch (f.data_type) {
      case 'number':
      case 'year':
        out[f.key] = Number(raw.replace(',', '.'))
        break
      case 'boolean':
        out[f.key] = raw === 'true'
        break
      default:
        out[f.key] = raw
    }
  }
  return out
}

function capitalize(s: string) {
  return s.charAt(0).toUpperCase() + s.slice(1)
}

export function Eigenschaftsformular({
  type,
  referate,
  gremien,
  qualificationTypes,
  initial,
  restrictReferate = null,
  onSubmit,
  onCancel,
  submitLabel = 'Speichern',
  onDerive,
}: Props) {
  const id = useId()
  const [draft, setDraft] = useState<Draft>(() => toDraft(type.fields, initial?.field_values))
  const [referat, setReferat] = useState(initial?.related_referat_id ?? '')
  const [gremium, setGremium] = useState(initial?.related_gremium_id ?? '')
  const [validFrom, setValidFrom] = useState(() => initial?.valid_from ?? new Date().toISOString().slice(0, 10))
  const [validTo, setValidTo] = useState(initial?.valid_to ?? '')
  const [error, setError] = useState<string | null>(null)
  const [errorField, setErrorField] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  // Bei bestehenden Einträgen gilt „gültig bis“ als vom Nutzer gesetzt (keine Vorbelegung beim Ändern)
  const [validUntilTouched, setValidUntilTouched] = useState(() => Boolean(initial?.field_values?.valid_until))
  const derives = Boolean(onDerive) && ['qualification_type', 'valid_until'].every((k) => type.fields.some((f) => f.key === k))
  const qualificationType = draft.qualification_type ?? ''
  const lastTraining = draft.last_training ?? ''

  useEffect(() => {
    if (!derives || validUntilTouched || !qualificationType || !validFrom) return
    let current = true
    onDerive!({ qualificationType, validFrom, lastTraining: lastTraining || null })
      .then((value) => {
        if (current) setDraft((d) => ({ ...d, valid_until: value ?? '' }))
      })
      .catch(() => undefined)
    return () => {
      current = false
    }
  }, [derives, validUntilTouched, qualificationType, validFrom, lastTraining, onDerive])

  const fromLabel = type.valid_from_label ?? 'gültig von'
  const toLabel = type.valid_to_label ?? 'gültig bis'

  // Bezug: inaktive nur, wenn schon gesetzt (R38); mit Reichweite Referat nur eigene (R41)
  const referatOptions = referate.filter(
    (r) => (r.is_active || r.id === initial?.related_referat_id) && (!restrictReferate || restrictReferate.includes(r.id) || r.id === initial?.related_referat_id),
  )
  const gremiumOptions = gremien.filter((g) => g.is_active || g.id === initial?.related_gremium_id)

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    setErrorField(null)
    if (validTo && validFrom && validTo < validFrom) {
      setError(`‚${capitalize(toLabel)}‘ darf nicht vor ‚${fromLabel}‘ liegen.`)
      return
    }
    setPending(true)
    try {
      const err = await onSubmit({
        field_values: toFieldValues(type.fields, draft),
        related_referat_id: type.relation_kind === 'referat' ? referat || null : null,
        related_gremium_id: type.relation_kind === 'gremium' ? gremium || null : null,
        valid_from: validFrom,
        valid_to: validTo || null,
      })
      if (err) {
        const detail = typeof err === 'object' && err && 'details' in err ? String((err as { details: unknown }).details ?? '') : ''
        setError(toMessage(err).text)
        setErrorField(type.fields.find((f) => f.label === detail)?.key ?? null)
      }
    } catch (caught) {
      setError(toMessage(caught).text)
    } finally {
      setPending(false)
    }
  }

  const selectClassName =
    'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm'

  return (
    <form className="flex flex-col gap-4 rounded-xl border p-4" onSubmit={handleSubmit} noValidate>
      <p className="font-medium">{type.name}</p>

      <div className="grid gap-4 sm:grid-cols-2">
        {type.fields.map((f) => {
          const fid = `${id}-${f.key}`
          const invalid = errorField === f.key
          const label = (
            <Label htmlFor={fid} className={invalid ? 'text-destructive' : undefined}>
              {f.label}
              {!f.is_required && <span className="font-normal text-muted-foreground"> (optional)</span>}
            </Label>
          )
          const common = { id: fid, required: f.is_required, 'aria-invalid': invalid || undefined, autoComplete: 'off' as const }
          const value = draft[f.key] ?? ''
          const setValue = (v: string) => {
            if (f.key === 'valid_until') setValidUntilTouched(true)
            setDraft((d) => ({ ...d, [f.key]: v }))
          }

          if (f.data_type === 'qualification_type') {
            return (
              <div key={f.key} className="sm:col-span-2">
                <QualifikationsartAuswahl
                  options={qualificationTypes}
                  value={value || null}
                  onChange={(v) => setValue(v ?? '')}
                  allowedKinds={f.allowed_qualification_kinds}
                  label={f.label}
                  required={f.is_required}
                  invalid={invalid}
                />
              </div>
            )
          }
          return (
            <div key={f.key} className="flex flex-col gap-2">
              {label}
              {f.data_type === 'choice' ? (
                <select {...common} value={value} onChange={(e) => setValue(e.target.value)} className={selectClassName}>
                  <option value="">{f.is_required ? '– bitte wählen –' : '–'}</option>
                  {(f.choice_values ?? []).map((c) => (
                    <option key={c} value={c}>
                      {c}
                    </option>
                  ))}
                </select>
              ) : f.data_type === 'boolean' ? (
                <select {...common} value={value} onChange={(e) => setValue(e.target.value)} className={selectClassName}>
                  <option value="">{f.is_required ? '– bitte wählen –' : '–'}</option>
                  <option value="true">ja</option>
                  <option value="false">nein</option>
                </select>
              ) : f.data_type === 'date' ? (
                <Input {...common} type="date" value={value} onChange={(e) => setValue(e.target.value)} />
              ) : f.data_type === 'year' ? (
                <Input {...common} type="number" inputMode="numeric" min={1900} max={2100} step={1} value={value} onChange={(e) => setValue(e.target.value)} />
              ) : f.data_type === 'number' ? (
                <Input {...common} type="number" inputMode="decimal" step="any" value={value} onChange={(e) => setValue(e.target.value)} />
              ) : (
                <Input {...common} type="text" value={value} onChange={(e) => setValue(e.target.value)} />
              )}
              <span className="sr-only">{DATA_TYPE_LABELS[f.data_type]}</span>
            </div>
          )
        })}

        {type.relation_kind === 'referat' && (
          <div className="flex flex-col gap-2">
            <Label htmlFor={`${id}-referat`}>
              Referat
              {!type.relation_required && <span className="font-normal text-muted-foreground"> (optional)</span>}
            </Label>
            <select id={`${id}-referat`} value={referat} onChange={(e) => setReferat(e.target.value)} required={type.relation_required} className={selectClassName}>
              <option value="">{type.relation_required ? '– bitte wählen –' : '–'}</option>
              {referatOptions.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.name}
                  {!r.is_active && ' (inaktiv)'}
                </option>
              ))}
            </select>
          </div>
        )}
        {type.relation_kind === 'gremium' && (
          <div className="flex flex-col gap-2">
            <Label htmlFor={`${id}-gremium`}>
              Gremium
              {!type.relation_required && <span className="font-normal text-muted-foreground"> (optional)</span>}
            </Label>
            <select id={`${id}-gremium`} value={gremium} onChange={(e) => setGremium(e.target.value)} required={type.relation_required} className={selectClassName}>
              <option value="">{type.relation_required ? '– bitte wählen –' : '–'}</option>
              {gremiumOptions.map((g) => (
                <option key={g.id} value={g.id}>
                  {g.name}
                  {!g.is_active && ' (inaktiv)'}
                </option>
              ))}
            </select>
          </div>
        )}

        <div className="flex flex-col gap-2">
          <Label htmlFor={`${id}-from`}>{capitalize(fromLabel)}</Label>
          <Input id={`${id}-from`} type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} required />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor={`${id}-to`}>
            {capitalize(toLabel)} <span className="font-normal text-muted-foreground">(optional)</span>
          </Label>
          <Input id={`${id}-to`} type="date" value={validTo} onChange={(e) => setValidTo(e.target.value)} />
        </div>
      </div>

      {error && (
        <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
          <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
          {error}
        </p>
      )}

      <div className="flex flex-wrap gap-3">
        <Button type="submit" disabled={pending}>
          {pending ? 'Speichern …' : submitLabel}
        </Button>
        <Button type="button" variant="outline" onClick={onCancel} disabled={pending}>
          Abbrechen
        </Button>
      </div>
    </form>
  )
}
