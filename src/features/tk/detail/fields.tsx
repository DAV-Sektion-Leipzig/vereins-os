import { useId, type ReactNode } from 'react'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { textareaClassName } from '@/features/tk/shared'
import { cn } from '@/lib/utils'

// Eingabefelder der Schritte 1–7 (Bezeichnungen und Hilfetexte nach Prototyp Abschnitt 3). Pflichtangaben aus
// tk_plan_results.missing werden markiert, sobald die Datenbank gerechnet hat.

type Base = { label: string; hint?: ReactNode; missing?: boolean; disabled?: boolean; className?: string }

function Wrap({ id, label, hint, missing, className, children }: Base & { id: string; children: ReactNode }) {
  return (
    <div className={cn('flex flex-col gap-2', className)}>
      <Label htmlFor={id} className={cn(missing && 'text-destructive')}>
        {label}
        {missing && <span className="sr-only"> (fehlt)</span>}
      </Label>
      {children}
      {hint && <p className="text-xs text-muted-foreground">{hint}</p>}
    </div>
  )
}

export function TextField(props: Base & { value: string | null; onChange: (v: string | null) => void; maxLength?: number; type?: string }) {
  const id = useId()
  return (
    <Wrap id={id} {...props}>
      <Input
        id={id}
        type={props.type ?? 'text'}
        value={props.value ?? ''}
        maxLength={props.maxLength}
        disabled={props.disabled}
        aria-invalid={props.missing || undefined}
        onChange={(e) => props.onChange(e.target.value === '' ? null : e.target.value)}
        autoComplete="off"
      />
    </Wrap>
  )
}

export function AreaField(props: Base & { value: string | null; onChange: (v: string | null) => void }) {
  const id = useId()
  return (
    <Wrap id={id} {...props}>
      <textarea
        id={id}
        className={textareaClassName}
        value={props.value ?? ''}
        disabled={props.disabled}
        maxLength={4000}
        aria-invalid={props.missing || undefined}
        onChange={(e) => props.onChange(e.target.value === '' ? null : e.target.value)}
      />
    </Wrap>
  )
}

export function NumberField(
  props: Base & { value: number | null; onChange: (v: number | null) => void; step?: number; min?: number; suffix?: ReactNode },
) {
  const id = useId()
  return (
    <Wrap id={id} {...props}>
      <div className="flex items-center gap-2">
        <Input
          id={id}
          type="number"
          inputMode="decimal"
          min={props.min ?? 0}
          step={props.step ?? 1}
          value={props.value ?? ''}
          disabled={props.disabled}
          aria-invalid={props.missing || undefined}
          className="w-32 tabular-nums"
          onChange={(e) => props.onChange(e.target.value === '' ? null : Number(e.target.value))}
        />
        {props.suffix}
      </div>
    </Wrap>
  )
}

export function SelectField<T extends string>(
  props: Base & { value: T | null; onChange: (v: T | null) => void; options: { value: T; label: string }[]; empty?: string },
) {
  const id = useId()
  return (
    <Wrap id={id} {...props}>
      <select
        id={id}
        className="h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:opacity-60 sm:text-sm"
        value={props.value ?? ''}
        disabled={props.disabled}
        aria-invalid={props.missing || undefined}
        onChange={(e) => props.onChange((e.target.value || null) as T | null)}
      >
        {props.empty !== undefined && <option value="">{props.empty}</option>}
        {props.options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </Wrap>
  )
}

export function RadioField<T extends string>(
  props: Base & { value: T | null; onChange: (v: T) => void; options: { value: T; label: string; hint?: string }[] },
) {
  const name = useId()
  return (
    <fieldset className={cn('flex flex-col gap-2', props.className)} disabled={props.disabled}>
      <legend className={cn('mb-2 text-sm font-medium', props.missing && 'text-destructive')}>{props.label}</legend>
      {props.options.map((o) => (
        <label key={o.value} className="flex items-start gap-3 text-sm">
          <input
            type="radio"
            name={name}
            checked={props.value === o.value}
            onChange={() => props.onChange(o.value)}
            className="mt-0.5 size-4 shrink-0 accent-primary"
          />
          <span>
            {o.label}
            {o.hint && <span className="block text-xs text-muted-foreground">{o.hint}</span>}
          </span>
        </label>
      ))}
      {props.hint && <p className="text-xs text-muted-foreground">{props.hint}</p>}
    </fieldset>
  )
}

export function CheckField(props: { label: ReactNode; checked: boolean; onChange: (v: boolean) => void; disabled?: boolean; missing?: boolean }) {
  return (
    <label className={cn('flex items-start gap-3 text-sm', props.missing && 'text-destructive')}>
      <input
        type="checkbox"
        checked={props.checked}
        disabled={props.disabled}
        onChange={(e) => props.onChange(e.target.checked)}
        className="mt-0.5 size-5 shrink-0 accent-primary"
      />
      <span>{props.label}</span>
    </label>
  )
}

/** Feld mit automatischem Vorschlag (Prototyp 4.2): „geändert“ und „Vorschlag übernehmen“. */
export function SuggestedNumber(props: {
  label: string
  value: number | null
  suggestion: number | null
  touched: boolean
  disabled?: boolean
  missing?: boolean
  hint?: ReactNode
  onChange: (v: number | null) => void
  onReset: () => void
}) {
  return (
    <NumberField
      label={props.label}
      value={props.touched ? props.value : (props.suggestion ?? props.value)}
      onChange={props.onChange}
      disabled={props.disabled}
      missing={props.missing}
      hint={props.hint}
      suffix={
        props.touched && props.suggestion !== null ? (
          <span className="flex items-center gap-2 text-xs text-muted-foreground">
            geändert (Vorschlag {props.suggestion})
            {!props.disabled && (
              <button type="button" className="underline underline-offset-4" onClick={props.onReset}>
                Vorschlag übernehmen
              </button>
            )}
          </span>
        ) : props.suggestion !== null ? (
          <span className="text-xs text-muted-foreground">Vorschlag</span>
        ) : null
      }
    />
  )
}

export function Section({ title, children, description }: { title: string; children: ReactNode; description?: ReactNode }) {
  return (
    <section className="flex flex-col gap-4">
      <div className="flex flex-col gap-1">
        <h2 className="text-lg font-semibold">{title}</h2>
        {description && <p className="text-sm text-muted-foreground">{description}</p>}
      </div>
      {children}
    </section>
  )
}
