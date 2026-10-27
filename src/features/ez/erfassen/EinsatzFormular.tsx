import { useEffect, useRef, useState, type FormEvent, type ReactNode } from 'react'
import { LockIcon, XIcon } from 'lucide-react'
import { Link, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { AnwesenheitsListe, PersonenEintragen } from '@/features/ez/erfassen/Anwesenheit'
import { loadRoster, mergeRosters, remunerationDefault, type FormContext, type ListPerson, type Roster } from '@/features/ez/erfassen/data'
import { clearDraft, writeDraft } from '@/features/ez/erfassen/draft'
import type { FormValues } from '@/features/ez/erfassen/values'
import { EZ_MESSAGES } from '@/features/ez/errors'
import { weekdayShort } from '@/features/ez/dates'
import { DAY_LABELS, fixedSpan, hasGroup, needsOrganizer, type DayCategory, type Role, type Span } from '@/features/ez/labels'
import { AktivenSuche, type ActivePerson } from '@/features/ez/shared/AktivenSuche'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { OrtAuswahl } from '@/features/ez/shared/OrtAuswahl'
import { ezRpc } from '@/features/ez/shared/rpc'
import { FormError, selectClassName } from '@/features/gr/shared/ui'
import { personName } from '@/lib/format'
import { cn } from '@/lib/utils'

type Props = {
  context: FormContext
  initial: FormValues
  /** Bearbeiten: id des Einsatzes; sonst Anlegen. */
  eventId?: string
  initialNames: Record<string, string>
  /** Einsatz aus der Planungshilfe: Kopf außer Bemerkung gesperrt, Personen aus der Planung fest (R25). */
  fromPlanning?: boolean
  lockedPersonIds?: string[]
  /** Abgerechneter Einsatz: Datum, Zeiten, Dauer, Vergütung und organisierende Person gesperrt (R34). */
  settled?: boolean
  settledPersonIds?: string[]
  /** Bezeichnung der gespeicherten Abrechnungsart (auch wenn inaktiv). */
  remunerationName?: string | null
  /** Name der Gruppe(n) beim Bearbeiten (nur angezeigt, R19). */
  groupLabel?: string
}

const TITLE_MAX = 90
const REMARK_MAX = 500
const TRIAL_MAX = 30

/** Feld aus EZ_FIELD_REQUIRED (detail) → id des Eingabefelds. */
const FIELD_IDS: Record<string, string> = {
  Gruppe: 'ez-group',
  Referat: 'ez-referat',
  Titel: 'ez-title',
  'Organisierende Person': 'ez-organizer',
  Datum: 'ez-start-date',
  Startdatum: 'ez-start-date',
  Enddatum: 'ez-end-date',
  Dauer: 'ez-day',
  Ort: 'ez-location',
}

// T023–T028 (US-EZ-01 bis -09, -12, -17 bis -21): Formular je Einsatzart in der Reihenfolge aus spec.md 6 mit Anwesenheit;
// Speichern über ez_save_event mit client_request_id, Rückfrage bei doppelter Erfassung (R8), Entwurf im Browser.
export function EinsatzFormular({
  context,
  initial,
  eventId,
  initialNames,
  fromPlanning = false,
  lockedPersonIds = [],
  settled = false,
  settledPersonIds = [],
  remunerationName = null,
  groupLabel,
}: Props) {
  const navigate = useNavigate()
  const isNew = !eventId
  const [values, setValues] = useState<FormValues>(initial)
  const [names, setNames] = useState<Record<string, string>>(initialNames)
  const [list, setList] = useState<ListPerson[]>([])
  const [trainingTime, setTrainingTime] = useState<Roster['training_times'] | null>(null)
  const [rosterNotice, setRosterNotice] = useState<string | null>(null)
  const [error, setError] = useState<{ text: string; field?: string } | null>(null)
  const [duplicate, setDuplicate] = useState<{ existingId: string | null } | null>(null)
  const [pending, setPending] = useState(false)
  const [editingOrganizer, setEditingOrganizer] = useState(!initial.organizerId)
  const rosterKey = useRef<string>('')

  const { kind } = values
  const withGroup = hasGroup(kind)
  const span = fixedSpan(kind) ?? values.span
  const headLocked = fromPlanning
  // Abgerechnet: Datum, Zeiten, Dauer und organisierende Person zusätzlich gesperrt (R34)
  const timesLocked = headLocked || settled
  const [locked] = useState(() => new Set(lockedPersonIds))
  const [settledIds] = useState(() => new Set(settledPersonIds))
  // Vergütung: Vorbelegung aus Einsatzart, Dauer und Datum, bis selbst gewählt (R32)
  const remunerationPreset = remunerationDefault(context, kind, span, values.startDate)
  const remunerationKindId = values.remunerationTouched ? values.remunerationKindId : remunerationPreset
  const set = (patch: Partial<FormValues>) => setValues((v) => ({ ...v, ...patch }))

  // Entwurf bei jeder Änderung (nur beim Anlegen, US-EZ-18)
  useEffect(() => {
    if (!isNew || !context.userId) return
    const timer = window.setTimeout(() => writeDraft(context.userId, values), 400)
    return () => window.clearTimeout(timer)
  }, [values, isNew, context.userId])

  // Anwesenheitsliste der Gruppe(n) zum Stichtag (R16, R30); beim Datumswechsel neu laden
  const groupIds = withGroup && values.groupId ? [values.groupId, ...values.additionalGroupIds] : []
  const key = groupIds.length > 0 && values.startDate ? `${groupIds.join(',')}@${values.startDate}` : ''
  useEffect(() => {
    if (!key) return
    let cancelled = false
    const [ids, date] = key.split('@')
    Promise.all(ids.split(',').map((id) => loadRoster(id, date))).then((rosters) => {
      if (cancelled) return
      const loaded = rosters.filter((r): r is Roster => r !== null)
      const merged = mergeRosters(loaded)
      setList(merged)
      setTrainingTime(rosters[0]?.training_times ?? null)
      setNames((n) => ({ ...n, ...Object.fromEntries(merged.map((p) => [p.person_id, personName(p)])) }))
      const previous = rosterKey.current
      rosterKey.current = key
      const inList = new Set(merged.map((p) => p.person_id))
      setValues((v) => {
        if (!previous) {
          // Erste Ladung (auch beim Bearbeiten): Personen außerhalb der Liste gelten als Vertretung
          const outside = v.persons.filter((p) => !inList.has(p.person_id) && p.role !== 'participant').map((p) => p.person_id)
          return { ...v, substituteIds: [...new Set([...v.substituteIds, ...outside])] }
        }
        const keep = v.persons.filter((p) => inList.has(p.person_id) || v.substituteIds.includes(p.person_id) || locked.has(p.person_id))
        const sameGroups = previous.split('@')[0] === ids
        if (sameGroups && keep.length !== v.persons.length) setRosterNotice('Die Liste wurde für das neue Datum aktualisiert.')
        return { ...v, persons: keep }
      })
    })
    return () => {
      cancelled = true
    }
  }, [key, locked])

  // Ohne Gruppe oder Datum keine Liste (abgeleitet statt im Effekt zurückgesetzt)
  const shownList = key ? list : []
  const shownTrainingTime = key ? trainingTime : null
  const groupOptions = context.groups
  const mainGroup = groupOptions.find((g) => g.id === values.groupId)
  const additionalOptions = groupOptions.filter(
    (g) => g.id !== values.groupId && g.referat_id === mainGroup?.referat_id && !values.additionalGroupIds.includes(g.id),
  )
  const staffSuggestions: ActivePerson[] = withGroup
    ? shownList.filter((p) => p.staff).map((p) => ({ id: p.person_id, first_name: p.first_name, preferred_name: p.preferred_name, last_name: p.last_name }))
    : values.persons.map((p) => {
        const [first, ...rest] = (names[p.person_id] ?? '').split(' ')
        return { id: p.person_id, first_name: first, preferred_name: null, last_name: rest.join(' ') }
      })

  function remember(person: ActivePerson) {
    setNames((n) => ({ ...n, [person.id]: personName(person) }))
  }

  function togglePerson(person: { person_id: string; defaultRole: Role }, checked: boolean) {
    setValues((v) => ({
      ...v,
      persons: checked
        ? [...v.persons.filter((p) => p.person_id !== person.person_id), { person_id: person.person_id, role: person.defaultRole, status: 'present' }]
        : v.persons.filter((p) => p.person_id !== person.person_id),
    }))
  }

  async function save(confirmDuplicate: boolean) {
    setError(null)
    setPending(true)
    const event: Record<string, unknown> = {
      ...(isNew ? { client_request_id: values.clientRequestId } : { id: eventId }),
      kind,
      span,
      group_id: withGroup ? values.groupId || null : null,
      referat_id: withGroup ? null : values.referatId || null,
      title: values.title,
      organizer_person_id: needsOrganizer(kind) ? values.organizerId || null : null,
      start_date: values.startDate || null,
      start_time: values.startTime || null,
      end_date: values.endDate || null,
      end_time: values.endTime || null,
      day_category: values.dayCategory || null,
      location_id: values.locationId || null,
      remark: values.remark,
      remuneration_kind_id: remunerationKindId || null,
    }
    if (isNew && kind === 'competition') event.additional_group_ids = values.additionalGroupIds
    const res = await ezRpc<string>('ez_save_event', {
      p_event: event,
      p_attendances: values.persons.map((p) => ({ person_id: p.person_id, role: p.role, status: withGroup ? 'present' : p.status })),
      p_trials: kind === 'training' ? values.trials : [],
      p_confirm_duplicate: confirmDuplicate,
    })
    setPending(false)
    if (res.error) {
      if (res.error.code === 'EZ_DUPLICATE_EVENT') return setDuplicate({ existingId: res.error.details || null })
      setDuplicate(null)
      const field =
        res.error.code === 'EZ_FIELD_REQUIRED'
          ? FIELD_IDS[res.error.details]
          : res.error.code === 'EZ_REMUNERATION_INACTIVE'
            ? 'ez-remuneration'
            : undefined
      setError({ text: res.error.text, field })
      if (field) document.getElementById(field)?.focus()
      return
    }
    if (isNew) clearDraft(context.userId)
    toast.success('Der Einsatz wurde gespeichert.')
    navigate(`/ez/${res.data}`)
  }

  function onSubmit(e: FormEvent) {
    e.preventDefault()
    void save(false)
  }

  function cancel() {
    if (isNew) clearDraft(context.userId)
    navigate(isNew ? '/ez' : `/ez/${eventId}`)
  }

  const invalid = (id: string) => error?.field === id || undefined
  const trainingTimeText =
    kind === 'training' && values.groupId && values.startDate && shownTrainingTime !== null
      ? shownTrainingTime.length > 0
        ? `Trainingszeit: ${weekdayShort(values.startDate)} ${shownTrainingTime.map((t) => `${t.starts_at}–${t.ends_at}`).join(', ')}`
        : 'Für diesen Wochentag ist keine Trainingszeit hinterlegt.'
      : null

  return (
    <form onSubmit={onSubmit} noValidate className="flex flex-col gap-6">
      {(kind === 'course' || kind === 'tour') && isNew && (
        <p className="rounded-lg border bg-muted/50 p-3 text-sm">Kurse und Touren aus der Planungshilfe Touren und Kurse werden automatisch angelegt.</p>
      )}
      {settled && (
        <p className="flex gap-2 rounded-lg border bg-muted/50 p-3 text-sm">
          <LockIcon className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
          Dieser Einsatz ist abgerechnet. Datum, Zeiten, Dauer, Vergütung, organisierende Person und abgerechnete Personen
          sind gesperrt. Änderungen nur nach Rücknahme des Abschlusses in Finanzen.
        </p>
      )}
      {fromPlanning && (
        <p className="rounded-lg border bg-muted/50 p-3 text-sm">
          Aus der Planungshilfe Touren und Kurse. Kopf und Personen aus der Planung werden dort geändert.
        </p>
      )}

      <div className="flex flex-col gap-5">
        {/* Ausbildungsfahrt und Wettkampfbetreuung: zuerst eintägig/mehrtägig (spec.md 6) */}
        {fixedSpan(kind) === null && withGroup && <SpanField value={span} onChange={(s) => set({ span: s })} disabled={timesLocked} />}

        {!withGroup && (
          <Field id="ez-referat" label="Referat">
            <select
              id="ez-referat"
              value={values.referatId}
              onChange={(e) => set({ referatId: e.target.value })}
              disabled={headLocked}
              aria-invalid={invalid('ez-referat')}
              className={selectClassName}
            >
              <option value="">Referat wählen</option>
              {context.referate.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.name}
                </option>
              ))}
            </select>
          </Field>
        )}

        {withGroup &&
          (isNew ? (
            <Field id="ez-group" label="Gruppe">
              <select
                id="ez-group"
                value={values.groupId}
                onChange={(e) => set({ groupId: e.target.value, additionalGroupIds: [] })}
                aria-invalid={invalid('ez-group')}
                className={selectClassName}
              >
                <option value="">Gruppe wählen</option>
                {groupOptions.some((g) => g.mine) && (
                  <optgroup label="Meine Gruppen">
                    {groupOptions.filter((g) => g.mine).map((g) => (
                      <option key={g.id} value={g.id}>
                        {g.name}
                      </option>
                    ))}
                  </optgroup>
                )}
                <optgroup label={groupOptions.some((g) => g.mine) ? 'Weitere Gruppen' : 'Gruppen'}>
                  {groupOptions.filter((g) => !g.mine).map((g) => (
                    <option key={g.id} value={g.id}>
                      {g.name}
                    </option>
                  ))}
                </optgroup>
              </select>
            </Field>
          ) : (
            <Field id="ez-group" label={values.additionalGroupIds.length > 0 ? 'Gruppen' : 'Gruppe'}>
              <p id="ez-group" className="text-sm">
                {groupLabel}
              </p>
            </Field>
          ))}

        {kind === 'competition' && isNew && values.groupId && (
          <div className="flex flex-col gap-2">
            {values.additionalGroupIds.length > 0 && (
              <ul className="flex flex-wrap gap-2">
                {values.additionalGroupIds.map((id) => (
                  <li key={id} className="flex items-center gap-1 rounded-lg border py-1 pr-1 pl-2.5 text-sm">
                    {groupOptions.find((g) => g.id === id)?.name}
                    <Button type="button"
                      variant="ghost"
                      size="icon-sm"
                      aria-label="Gruppe entfernen"
                      onClick={() => set({ additionalGroupIds: values.additionalGroupIds.filter((g) => g !== id) })}
                    >
                      <XIcon aria-hidden="true" />
                    </Button>
                  </li>
                ))}
              </ul>
            )}
            {additionalOptions.length > 0 && (
              <div className="flex flex-col gap-2">
                <Label htmlFor="ez-more-group">Weitere Gruppe hinzufügen</Label>
                <select
                  id="ez-more-group"
                  value=""
                  onChange={(e) => e.target.value && set({ additionalGroupIds: [...values.additionalGroupIds, e.target.value] })}
                  className={selectClassName}
                >
                  <option value="">Gruppe desselben Referats wählen</option>
                  {additionalOptions.map((g) => (
                    <option key={g.id} value={g.id}>
                      {g.name}
                    </option>
                  ))}
                </select>
              </div>
            )}
          </div>
        )}

        {kind !== 'training' && (
          <Field id="ez-title" label="Titel">
            <Input
              id="ez-title"
              value={values.title}
              onChange={(e) => set({ title: e.target.value })}
              maxLength={TITLE_MAX}
              disabled={headLocked}
              aria-invalid={invalid('ez-title')}
            />
          </Field>
        )}

        {needsOrganizer(kind) && (
          <div className="flex flex-col gap-2">
            {values.organizerId && !editingOrganizer ? (
              <>
                <Label htmlFor="ez-organizer">Organisierende Person</Label>
                <div className="flex items-center justify-between gap-3 rounded-xl border px-3 py-2">
                  <span id="ez-organizer" className="font-medium">
                    {names[values.organizerId] ?? 'ausgewählte Person'}
                  </span>
                  {!timesLocked && (
                    <Button type="button" variant="ghost" size="sm" onClick={() => setEditingOrganizer(true)}>
                      Ändern
                    </Button>
                  )}
                </div>
              </>
            ) : (
              <div id="ez-organizer" tabIndex={-1} className={cn('rounded-xl', invalid('ez-organizer') && 'ring-3 ring-destructive/20')}>
                <AktivenSuche
                  label="Organisierende Person"
                  suggestions={staffSuggestions}
                  suggestionsTitle={withGroup ? 'Aus der Gruppe' : 'Bereits eingetragen'}
                  onSelect={(person) => {
                    remember(person)
                    set({ organizerId: person.id })
                    setEditingOrganizer(false)
                  }}
                />
              </div>
            )}
          </div>
        )}

        {fixedSpan(kind) === null && !withGroup && <SpanField value={span} onChange={(s) => set({ span: s })} disabled={timesLocked} />}

        {span === 'single' ? (
          <div className="flex flex-col gap-4 sm:flex-row sm:flex-wrap sm:items-start">
            <Field id="ez-start-date" label="Datum" hint={trainingTimeText}>
              <Input
                id="ez-start-date"
                type="date"
                value={values.startDate}
                onChange={(e) => {
                  setRosterNotice(null)
                  set({ startDate: e.target.value })
                }}
                disabled={timesLocked}
                aria-invalid={invalid('ez-start-date')}
                className="sm:w-44"
              />
            </Field>
            {kind !== 'training' && (
              <fieldset className="flex flex-col gap-2">
                <legend id="ez-day" tabIndex={-1} className="mb-2 text-sm font-medium">
                  Dauer
                </legend>
                <div className="flex flex-wrap gap-2">
                  {(['under_8h', 'at_least_8h'] as DayCategory[]).map((d) => (
                    <label
                      key={d}
                      className={cn(
                        'flex min-h-11 cursor-pointer items-center gap-2 rounded-lg border px-3 text-sm sm:min-h-8',
                        values.dayCategory === d && 'border-primary bg-primary/5',
                        invalid('ez-day') && 'border-destructive',
                      )}
                    >
                      <input
                        type="radio"
                        name="ez-day"
                        value={d}
                        checked={values.dayCategory === d}
                        onChange={() => set({ dayCategory: d })}
                        disabled={timesLocked}
                        className="accent-primary"
                      />
                      {DAY_LABELS[d]}
                    </label>
                  ))}
                </div>
              </fieldset>
            )}
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-4 sm:flex-row sm:flex-wrap">
              <Field id="ez-start-date" label="Startdatum">
                <Input
                  id="ez-start-date"
                  type="date"
                  value={values.startDate}
                  onChange={(e) => {
                    setRosterNotice(null)
                    set({ startDate: e.target.value })
                  }}
                  disabled={timesLocked}
                  aria-invalid={invalid('ez-start-date')}
                  className="sm:w-44"
                />
              </Field>
              <Field id="ez-start-time" label="Beginn (optional)" hint="Abfahrt am Startort">
                <Input
                  id="ez-start-time"
                  type="time"
                  value={values.startTime}
                  onChange={(e) => set({ startTime: e.target.value })}
                  disabled={timesLocked}
                  className="sm:w-32"
                />
              </Field>
            </div>
            <div className="flex flex-col gap-4 sm:flex-row sm:flex-wrap">
              <Field id="ez-end-date" label="Enddatum">
                <Input
                  id="ez-end-date"
                  type="date"
                  value={values.endDate}
                  min={values.startDate || undefined}
                  onChange={(e) => set({ endDate: e.target.value })}
                  disabled={timesLocked}
                  aria-invalid={invalid('ez-end-date')}
                  className="sm:w-44"
                />
              </Field>
              <Field id="ez-end-time" label="Ende (optional)" hint="Rückkehr am Startort">
                <Input
                  id="ez-end-time"
                  type="time"
                  value={values.endTime}
                  onChange={(e) => set({ endTime: e.target.value })}
                  disabled={timesLocked}
                  className="sm:w-32"
                />
              </Field>
            </div>
          </div>
        )}

        <VerguetungField
          context={context}
          value={remunerationKindId}
          preset={remunerationPreset}
          touched={values.remunerationTouched}
          storedName={remunerationName}
          disabled={settled}
          invalid={error?.field === 'ez-remuneration'}
          onChange={(id) => set({ remunerationKindId: id, remunerationTouched: true })}
        />

        {kind === 'training' && (
          <Field id="ez-location" label="Ort">
            <OrtAuswahl
              id="ez-location"
              locations={context.locations}
              value={values.locationId}
              onChange={(v) => set({ locationId: v })}
              invalid={invalid('ez-location')}
            />
          </Field>
        )}
      </div>

      <section aria-labelledby="ez-form-attendance" className="flex flex-col gap-3">
        <h2 id="ez-form-attendance" className="text-lg font-semibold">
          {withGroup ? 'Anwesenheit' : 'Personen'}
        </h2>
        {rosterNotice && (
          <p role="status" className="text-sm text-muted-foreground">
            {rosterNotice}
          </p>
        )}
        {withGroup ? (
          values.groupId && values.startDate ? (
            <AnwesenheitsListe
              list={shownList}
              persons={values.persons}
              substitutes={values.substituteIds.map((id) => ({ id, name: names[id] ?? 'unbekannte Person' }))}
              lockedIds={locked}
              settledIds={settledIds}
              disabled={pending}
              onToggle={togglePerson}
              onRole={(id, role) => set({ persons: values.persons.map((p) => (p.person_id === id ? { ...p, role } : p)) })}
              onAddSubstitute={(person) => {
                remember(person)
                setValues((v) => ({
                  ...v,
                  substituteIds: [...v.substituteIds, person.id],
                  persons: [...v.persons, { person_id: person.id, role: 'trainer', status: 'present' }],
                }))
              }}
            />
          ) : (
            <p className="text-sm text-muted-foreground">Bitte zuerst Gruppe und Datum wählen.</p>
          )
        ) : (
          <PersonenEintragen
            persons={values.persons}
            names={names}
            defaultRole={kind === 'work_assignment' ? 'helper' : 'trainer'}
            lockedIds={locked}
            settledIds={settledIds}
            disabled={pending}
            onAdd={(person) => {
              remember(person)
              set({ persons: [...values.persons, { person_id: person.id, role: kind === 'work_assignment' ? 'helper' : 'trainer', status: 'registered' }] })
            }}
            onChange={(id, patch) => set({ persons: values.persons.map((p) => (p.person_id === id ? { ...p, ...patch } : p)) })}
            onRemove={(id) => set({ persons: values.persons.filter((p) => p.person_id !== id) })}
          />
        )}
      </section>

      {kind === 'training' && (
        <section aria-labelledby="ez-form-trials" className="flex flex-col gap-3">
          <h2 id="ez-form-trials" className="text-lg font-semibold">
            Probetraining
          </h2>
          <p className="text-sm text-muted-foreground">Nur Vorname eintragen.</p>
          {values.trials.map((t, i) => (
            <div key={i} className="flex items-center gap-2">
              <Input
                aria-label={`Probetraining ${i + 1}, Vorname`}
                value={t}
                maxLength={TRIAL_MAX}
                onChange={(e) => set({ trials: values.trials.map((x, j) => (j === i ? e.target.value : x)) })}
                className="sm:w-64"
              />
              <Button type="button"
                variant="ghost"
                size="icon"
                aria-label={`Probetraining ${i + 1} entfernen`}
                onClick={() => set({ trials: values.trials.filter((_, j) => j !== i) })}
                className="size-11 sm:size-8"
              >
                <XIcon aria-hidden="true" />
              </Button>
            </div>
          ))}
          <Button type="button" variant="outline" className="h-11 self-start sm:h-8" onClick={() => set({ trials: [...values.trials, ''] })}>
            Probetraining hinzufügen
          </Button>
        </section>
      )}

      <Field id="ez-remark" label="Bemerkung (optional)" hint="Keine Angaben zu Gesundheit oder anderen sensiblen Daten von Kindern.">
        <textarea
          id="ez-remark"
          value={values.remark}
          onChange={(e) => set({ remark: e.target.value })}
          maxLength={REMARK_MAX}
          rows={3}
          className="min-h-20 w-full rounded-lg border border-input bg-background px-2.5 py-2 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:text-sm"
        />
      </Field>

      <FormError text={error?.text ?? null} />
      <div className="flex flex-wrap gap-2">
        <Button type="submit" disabled={pending} className="h-11 sm:h-8">
          {pending ? 'Wird gespeichert …' : 'Speichern'}
        </Button>
        <Button type="button" variant="outline" onClick={cancel} disabled={pending} className="h-11 sm:h-8">
          Abbrechen
        </Button>
      </div>

      {duplicate && (
        <ConfirmDialog
          title="Doppelte Erfassung?"
          confirmLabel="Trotzdem speichern"
          pendingLabel="Wird gespeichert …"
          pending={pending}
          error={null}
          onConfirm={() => save(true)}
          onClose={() => setDuplicate(null)}
        >
          {EZ_MESSAGES.duplicateEvent}
          {duplicate.existingId && (
            <>
              {' '}
              <Link to={`/ez/${duplicate.existingId}`} target="_blank" className="underline underline-offset-4">
                Vorhandenen Einsatz ansehen
              </Link>
            </>
          )}
        </ConfirmDialog>
      )}
    </form>
  )
}

function Field({ id, label, hint, children }: { id: string; label: string; hint?: string | null; children: ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      <Label htmlFor={id}>{label}</Label>
      {children}
      {hint && <p className="text-sm text-muted-foreground">{hint}</p>}
    </div>
  )
}

function SpanField({ value, onChange, disabled }: { value: Span; onChange: (span: Span) => void; disabled: boolean }) {
  return (
    <fieldset className="flex flex-col gap-2">
      <legend className="mb-2 text-sm font-medium">Dauer des Einsatzes</legend>
      <div className="flex flex-wrap gap-2">
        {(['single', 'multi'] as Span[]).map((s) => (
          <label
            key={s}
            className={cn(
              'flex min-h-11 cursor-pointer items-center gap-2 rounded-lg border px-3 text-sm sm:min-h-8',
              value === s && 'border-primary bg-primary/5',
            )}
          >
            <input type="radio" name="ez-span" value={s} checked={value === s} onChange={() => onChange(s)} disabled={disabled} className="accent-primary" />
            {s === 'single' ? 'eintägig' : 'mehrtägig'}
          </label>
        ))}
      </div>
    </fieldset>
  )
}

const NO_REMUNERATION = 'keine Vergütung'

/**
 * Feld „Vergütung“ (spec.md EZ 6, v0.6; R32): aktive Abrechnungsarten nach Bezeichnung und „keine Vergütung“;
 * die gespeicherte Abrechnungsart bleibt wählbar, auch wenn sie inzwischen inaktiv ist.
 */
function VerguetungField({
  context,
  value,
  preset,
  touched,
  storedName,
  disabled,
  invalid,
  onChange,
}: {
  context: FormContext
  value: string
  preset: string
  touched: boolean
  storedName: string | null
  disabled: boolean
  invalid: boolean
  onChange: (id: string) => void
}) {
  const options = context.remunerationKinds.filter((k) => k.is_active || k.id === value)
  const nameOf = (id: string) =>
    id ? (context.remunerationKinds.find((k) => k.id === id)?.name ?? (id === value ? storedName : null) ?? 'unbekannte Abrechnungsart') : NO_REMUNERATION
  // Wechsel der Einsatzart bzw. Dauer: gewählte Abrechnungsart bleibt, neue Vorbelegung als Hinweis [ANNAHME R32]
  const hint =
    touched && !disabled && value !== preset
      ? `Vorbelegung für diesen Einsatz: ${nameOf(preset)}.`
      : 'Vorbelegt aus der Einsatzart. Ändern nur, wenn für diesen Einsatz eine andere Vergütung gilt.'
  return (
    <Field id="ez-remuneration" label="Vergütung" hint={hint}>
      <select
        id="ez-remuneration"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        disabled={disabled}
        aria-invalid={invalid || undefined}
        className={selectClassName}
      >
        <option value="">{NO_REMUNERATION}</option>
        {value && !options.some((k) => k.id === value) && <option value={value}>{nameOf(value)}</option>}
        {options.map((k) => (
          <option key={k.id} value={k.id}>
            {k.is_active ? k.name : `${k.name} (inaktiv)`}
          </option>
        ))}
      </select>
    </Field>
  )
}
