import { SlidersHorizontalIcon, XIcon } from 'lucide-react'
import { Link, useSubmit } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import {
  DEFAULT_STATUS,
  EXPIRY_FILTERS,
  filterHref,
  VOLUNTEER_STATUS_LABELS,
  type FilterOptions,
  type QualificationOption,
  type VolunteerFilter,
} from '@/features/ea/aktive/data'
import { cn } from '@/lib/utils'

const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:w-auto sm:max-w-56 sm:text-sm'

const checkboxClassName = 'size-4 accent-primary'

// Mehrfachauswahl als anklickbare Chips: das Kästchen bleibt für Tastatur und Screenreader, sichtbar ist nur der Chip.
const chipClassName =
  'inline-flex h-7 cursor-pointer items-center rounded-4xl border border-input px-3 text-sm transition-colors has-checked:border-primary has-checked:bg-status-active-bg has-checked:font-medium has-checked:text-primary has-focus-visible:ring-3 has-focus-visible:ring-ring/50'

type Props = {
  filter: VolunteerFilter
  options: FilterOptions
  /** Referate, auf die der Zugang beschränkt ist (Referent:in); null = alle. */
  ownReferate: string[] | null
  open: boolean
  onToggle: () => void
  /** Suchfeld, steht in der Zeile vor dem Knopf „Filter“. */
  search: React.ReactNode
  showReset: boolean
}

// T036 (US-EA-03): Filterleiste innerhalb des Suchformulars der Übersicht; jede Änderung lädt die Liste neu.
// Eingeklappt (Entscheidung Product Owner 27.10.2026): eine Zeile mit Suche, Knopf „Filter (n)“ und den gesetzten
// Filtern als Chips mit „entfernen“; der Kasten mit allen Filtern klappt auf Klick auf. Die Auswahl richtet sich
// nach den Rechten (US-EA-03 AK4). Ob der Kasten offen ist, hält die Seite, damit er beim Neuladen offen bleibt.
export function Filterleiste({ filter, options, ownReferate, open, onToggle, search, showReset }: Props) {
  const submit = useSubmit()
  const count = countFilters(filter, options)
  const chips = activeChips(filter, options, ownReferate)

  function onChange(event: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) {
    submit(event.currentTarget.form, { replace: true })
  }

  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-2">
        {search}
        <Button type="button" variant="outline" aria-expanded={open} aria-controls="ea-filter" onClick={onToggle}>
          <SlidersHorizontalIcon data-icon="inline-start" aria-hidden="true" />
          {count > 0 ? `Filter (${count})` : 'Filter'}
        </Button>
        {chips.length > 0 && (
          <ul className="flex flex-wrap items-center gap-2" aria-label="Gesetzte Filter">
            {chips.map((chip) => (
              <li key={chip.key}>
                <Link
                  to={chip.removeHref}
                  replace
                  className="inline-flex h-7 items-center gap-1 rounded-4xl border border-primary bg-status-active-bg pr-2 pl-3 text-sm font-medium text-primary hover:bg-primary/15"
                  aria-label={`Filter „${chip.label}“ entfernen`}
                >
                  {chip.label}
                  <XIcon className="size-3.5" aria-hidden="true" />
                </Link>
              </li>
            ))}
          </ul>
        )}
        {showReset && (
          <Button variant="ghost" asChild>
            <Link to="/ea/aktive">Filter zurücksetzen</Link>
          </Button>
        )}
      </div>

      <div
        id="ea-filter"
        role="group"
        aria-label="Filter"
        className={cn('flex-col gap-4 rounded-xl border p-4', open ? 'flex' : 'hidden')}
      >
        <div className="flex flex-col gap-4 sm:flex-row sm:flex-wrap">
          <fieldset className="flex flex-col gap-2">
            <legend className="mb-2 text-sm font-medium">Ehrenamtsstatus</legend>
            <div className="flex flex-wrap gap-2">
              {options.statuses.map((s) => (
                <label key={s} className={chipClassName}>
                  <input
                    type="checkbox"
                    name="status"
                    value={s}
                    defaultChecked={filter.status.includes(s)}
                    onChange={onChange}
                    className="sr-only"
                  />
                  {VOLUNTEER_STATUS_LABELS[s]}
                </label>
              ))}
            </div>
          </fieldset>

          {options.referate.length > 0 && (
            <fieldset className="flex flex-col gap-2">
              <legend className="mb-2 text-sm font-medium">Referat</legend>
              <div className="flex flex-wrap gap-2">
                {options.referate.map((r) => (
                  <label key={r.id} className={chipClassName}>
                    <input
                      type="checkbox"
                      name="referat"
                      value={r.id}
                      defaultChecked={filter.referate.includes(r.id)}
                      onChange={onChange}
                      className="sr-only"
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
                    {qualificationLabel(q)}
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
          <label className="flex h-8 items-center gap-2 text-sm">
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
          <label className="flex h-8 items-center gap-2 text-sm">
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

function qualificationLabel(q: QualificationOption): string {
  return q.code ? `${q.code} – ${q.name}` : q.name
}

function groupByDiscipline(types: QualificationOption[]): [string, QualificationOption[]][] {
  const groups = new Map<string, QualificationOption[]>()
  for (const t of types) groups.set(t.discipline, [...(groups.get(t.discipline) ?? []), t])
  return [...groups.entries()]
}

/** Zahl der gesetzten Filter für den Knopf (Status und Referat zählen nur abweichend von der Vorbelegung). */
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

type Chip = { key: string; label: string; removeHref: string }

/** Gesetzte Filter als Chips; „entfernen“ führt auf die Adresse ohne diesen Filter (Seite 1). Die Suche hat ihr Feld. */
function activeChips(filter: VolunteerFilter, options: FilterOptions, ownReferate: string[] | null): Chip[] {
  const chips: Chip[] = []
  const href = (patch: Partial<VolunteerFilter>) => filterHref({ ...filter, ...patch }, 1)
  const name = (list: { id: string; name: string }[] | null, id: string) => list?.find((o) => o.id === id)?.name ?? id

  if (filter.status.join() !== DEFAULT_STATUS.join()) {
    chips.push({
      key: 'status',
      label: `Status: ${filter.status.map((s) => VOLUNTEER_STATUS_LABELS[s]).join(', ')}`,
      removeHref: href({ status: DEFAULT_STATUS }),
    })
  }
  if (filter.referate.join() !== (ownReferate ?? []).join()) {
    for (const id of filter.referate) {
      chips.push({
        key: `referat-${id}`,
        label: `Referat: ${name(options.referate, id)}`,
        removeHref: href({ referate: filter.referate.filter((r) => r !== id) }),
      })
    }
  }
  if (filter.func) chips.push({ key: 'funktion', label: `Funktion: ${filter.func}`, removeHref: href({ func: '' }) })
  if (filter.position) chips.push({ key: 'amt', label: `Amt: ${filter.position}`, removeHref: href({ position: '' }) })
  if (filter.gremium) {
    chips.push({ key: 'gremium', label: `Gremium: ${name(options.gremien, filter.gremium)}`, removeHref: href({ gremium: '' }) })
  }
  if (filter.qualification) {
    const q = options.qualificationTypes.find((t) => t.id === filter.qualification)
    chips.push({
      key: 'qualifikation',
      label: `Qualifikation: ${q ? qualificationLabel(q) : filter.qualification}`,
      removeHref: href({ qualification: '' }),
    })
  }
  if (filter.discipline) chips.push({ key: 'sparte', label: `Sparte: ${filter.discipline}`, removeHref: href({ discipline: '' }) })
  if (filter.expiry) {
    chips.push({ key: 'ablauf', label: `Ablaufstatus: ${EXPIRY_FILTERS[filter.expiry]}`, removeHref: href({ expiry: '' }) })
  }
  if (filter.withoutLicense) {
    chips.push({ key: 'ohne-lizenz', label: 'Trainer:in ohne gültige Lizenz', removeHref: href({ withoutLicense: false }) })
  }
  if (filter.withoutAssignment) {
    chips.push({ key: 'ohne-zuordnung', label: 'aktiv ohne Funktion oder Amt', removeHref: href({ withoutAssignment: false }) })
  }
  return chips
}
