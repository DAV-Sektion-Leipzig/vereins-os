import { useState } from 'react'
import { SlidersHorizontalIcon } from 'lucide-react'
import { useSubmit } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import {
  DEFAULT_STATUS,
  EXPIRY_FILTERS,
  VOLUNTEER_STATUS_LABELS,
  type FilterOptions,
  type QualificationOption,
  type VolunteerFilter,
} from '@/features/ea/aktive/data'
import { cn } from '@/lib/utils'

const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:w-auto sm:max-w-56 sm:text-sm'

const checkboxClassName = 'size-4 accent-primary'

type Props = { filter: VolunteerFilter; options: FilterOptions; children?: React.ReactNode }

// T036 (US-EA-03): Filterleiste innerhalb des Suchformulars der Übersicht; jede Änderung lädt die Liste neu.
// Auf schmalen Bildschirmen eingeklappt. Die Auswahl richtet sich nach den Rechten (US-EA-03 AK4).
// Eigener Kasten mit Überschrift, damit Filter und Kennzeichen der Tabelle nicht doppelt wirken; children z. B. „Filter zurücksetzen“.
export function Filterleiste({ filter, options, children }: Props) {
  const submit = useSubmit()
  const [open, setOpen] = useState(false)
  const count = countFilters(filter, options)

  function onChange(event: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) {
    submit(event.currentTarget.form, { replace: true })
  }

  return (
    <div className="flex flex-col gap-3">
      <Button
        type="button"
        variant="outline"
        className="self-start sm:hidden"
        aria-expanded={open}
        aria-controls="ea-filter"
        onClick={() => setOpen((o) => !o)}
      >
        <SlidersHorizontalIcon data-icon="inline-start" aria-hidden="true" />
        {count > 0 ? `Filter (${count})` : 'Filter'}
      </Button>

      <div
        id="ea-filter"
        role="group"
        aria-labelledby="ea-filter-heading"
        className={cn('flex-col gap-4 rounded-xl border p-4 sm:flex', open ? 'flex' : 'hidden')}
      >
        <h2 id="ea-filter-heading" className="sr-only text-base font-semibold sm:not-sr-only">
          Filter
        </h2>
        <div className="flex flex-col gap-4 sm:flex-row sm:flex-wrap">
          <fieldset className="flex flex-col gap-2">
            <legend className="mb-2 text-sm font-medium">Ehrenamtsstatus</legend>
            <div className="flex flex-wrap gap-x-4 gap-y-2">
              {options.statuses.map((s) => (
                <label key={s} className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    name="status"
                    value={s}
                    defaultChecked={filter.status.includes(s)}
                    onChange={onChange}
                    className={checkboxClassName}
                  />
                  {VOLUNTEER_STATUS_LABELS[s]}
                </label>
              ))}
            </div>
          </fieldset>

          {options.referate.length > 0 && (
            <fieldset className="flex flex-col gap-2">
              <legend className="mb-2 text-sm font-medium">Referat</legend>
              <div className="flex flex-wrap gap-x-4 gap-y-2">
                {options.referate.map((r) => (
                  <label key={r.id} className="flex items-center gap-2 text-sm">
                    <input
                      type="checkbox"
                      name="referat"
                      value={r.id}
                      defaultChecked={filter.referate.includes(r.id)}
                      onChange={onChange}
                      className={checkboxClassName}
                    />
                    {r.name}
                  </label>
                ))}
              </div>
            </fieldset>
          )}
        </div>

        <div className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end">
          <Choice id="ea-filter-funktion" name="funktion" label="Funktion" value={filter.func} onChange={onChange}>
            {options.functions.map((f) => (
              <option key={f} value={f}>
                {f}
              </option>
            ))}
          </Choice>
          <Choice id="ea-filter-amt" name="amt" label="Amt" value={filter.position} onChange={onChange}>
            {options.positions.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </Choice>
          {options.gremien && (
            <Choice id="ea-filter-gremium" name="gremium" label="Gremium" value={filter.gremium} onChange={onChange}>
              {options.gremien.map((g) => (
                <option key={g.id} value={g.id}>
                  {g.name}
                </option>
              ))}
            </Choice>
          )}
          <Choice
            id="ea-filter-qualifikation"
            name="qualifikation"
            label="Qualifikation"
            value={filter.qualification}
            onChange={onChange}
          >
            {groupByDiscipline(options.qualificationTypes).map(([discipline, types]) => (
              <optgroup key={discipline} label={discipline}>
                {types.map((q) => (
                  <option key={q.id} value={q.id}>
                    {q.code ? `${q.code} – ${q.name}` : q.name}
                  </option>
                ))}
              </optgroup>
            ))}
          </Choice>
          <Choice id="ea-filter-sparte" name="sparte" label="Sparte" value={filter.discipline} onChange={onChange}>
            {options.disciplines.map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </Choice>
          <Choice id="ea-filter-ablauf" name="ablauf" label="Ablaufstatus" value={filter.expiry} onChange={onChange}>
            {Object.entries(EXPIRY_FILTERS).map(([key, label]) => (
              <option key={key} value={key}>
                {label}
              </option>
            ))}
          </Choice>
        </div>

        <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:gap-x-6">
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              name="ohne_lizenz"
              value="1"
              defaultChecked={filter.withoutLicense}
              onChange={onChange}
              className={checkboxClassName}
            />
            Trainer:in ohne gültige Lizenz
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              name="ohne_zuordnung"
              value="1"
              defaultChecked={filter.withoutAssignment}
              onChange={onChange}
              className={checkboxClassName}
            />
            aktiv ohne Funktion oder Amt
          </label>
        </div>
        {children}
      </div>
    </div>
  )
}

type ChoiceProps = {
  id: string
  name: string
  label: string
  value: string
  onChange: (event: React.ChangeEvent<HTMLSelectElement>) => void
  children: React.ReactNode
}

function Choice({ id, name, label, value, onChange, children }: ChoiceProps) {
  return (
    <div className="flex flex-col gap-2">
      <Label htmlFor={id}>{label}</Label>
      <select id={id} name={name} defaultValue={value} onChange={onChange} className={selectClassName}>
        <option value="">alle</option>
        {children}
      </select>
    </div>
  )
}

function groupByDiscipline(types: QualificationOption[]): [string, QualificationOption[]][] {
  const groups = new Map<string, QualificationOption[]>()
  for (const t of types) groups.set(t.discipline, [...(groups.get(t.discipline) ?? []), t])
  return [...groups.entries()]
}

/** Zahl der gesetzten Filter für den eingeklappten Knopf (Status und Referat zählen nur abweichend von der Vorbelegung). */
function countFilters(filter: VolunteerFilter, options: FilterOptions): number {
  const statusChanged = filter.status.join() !== DEFAULT_STATUS.join()
  const referatChanged = filter.referate.length > 0 && filter.referate.length < options.referate.length
  return [
    statusChanged,
    referatChanged,
    filter.func,
    filter.position,
    filter.gremium,
    filter.qualification,
    filter.discipline,
    filter.expiry,
    filter.withoutLicense,
    filter.withoutAssignment,
  ].filter(Boolean).length
}
