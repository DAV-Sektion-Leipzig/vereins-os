import { useState } from 'react'
import { UserPlusIcon, XIcon } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import type { ListPerson } from '@/features/ez/erfassen/data'
import { ROLE_LABELS, STATUS_LABELS, type AttendanceStatus, type Role } from '@/features/ez/labels'
import { AktivenSuche, type ActivePerson } from '@/features/ez/shared/AktivenSuche'
import { SettledBadge } from '@/features/ez/shared/SettledBadge'
import { selectClassName } from '@/features/gr/shared/ui'
import { personName } from '@/lib/format'
import { cn } from '@/lib/utils'

export type FormPerson = { person_id: string; role: Role; status: AttendanceStatus }

type ListProps = {
  list: ListPerson[]
  persons: FormPerson[]
  substitutes: { id: string; name: string }[]
  lockedIds: Set<string>
  /** Abgerechnete Personen (R34 EZ): fest wie Personen aus der Planung, mit Kennzeichen „abgerechnet“. */
  settledIds: Set<string>
  disabled: boolean
  onToggle: (person: { person_id: string; defaultRole: Role }, checked: boolean) => void
  onRole: (personId: string, role: Role) => void
  onAddSubstitute: (person: ActivePerson) => void
}

// T024 (US-EZ-02, -03; R16, R17, R20): Liste der Gruppe zum Stichtag mit Kontrollkästchen (≥ 44 px), Rolle nur bei
// angehakten Trainer:innen und Helfer:innen, Zähler je Abschnitt; Vertretung über die Personensuche „Aktive“.
export function AnwesenheitsListe({ list, persons, substitutes, lockedIds, settledIds, disabled, onToggle, onRole, onAddSubstitute }: ListProps) {
  const [searching, setSearching] = useState(false)
  const checked = new Map(persons.map((p) => [p.person_id, p]))
  const staff = list.filter((p) => p.staff)
  const participants = list.filter((p) => !p.staff)
  const staffChecked = persons.filter((p) => p.role !== 'participant').length
  const participantsChecked = persons.filter((p) => p.role === 'participant').length

  return (
    <div className="flex flex-col gap-5">
      <fieldset className="flex flex-col gap-2">
        <legend className="mb-2 flex w-full items-baseline justify-between gap-3 font-medium">
          Trainer:innen und Helfer:innen
          <span className="text-sm font-normal text-muted-foreground tabular-nums">{staffChecked} ausgewählt</span>
        </legend>
        <ul className="flex flex-col divide-y rounded-xl border">
          {staff.map((p) => (
            <Row
              key={p.person_id}
              id={p.person_id}
              name={personName(p)}
              selected={checked.get(p.person_id)}
              withRole
              locked={lockedIds.has(p.person_id)}
              settled={settledIds.has(p.person_id)}
              disabled={disabled}
              onToggle={(on) => onToggle(p, on)}
              onRole={onRole}
            />
          ))}
          {substitutes.map((s) => (
            <Row
              key={s.id}
              id={s.id}
              name={s.name}
              badge="Vertretung"
              selected={checked.get(s.id)}
              withRole
              locked={lockedIds.has(s.id)}
              settled={settledIds.has(s.id)}
              disabled={disabled}
              onToggle={(on) => onToggle({ person_id: s.id, defaultRole: 'trainer' }, on)}
              onRole={onRole}
            />
          ))}
          {staff.length + substitutes.length === 0 && (
            <li className="px-3 py-2.5 text-sm text-muted-foreground">Keine Trainer:innen oder Helfer:innen in der Gruppe.</li>
          )}
        </ul>
        {searching ? (
          <div className="flex flex-col gap-2 rounded-xl border p-3">
            <AktivenSuche
              label="Vertretung suchen"
              excludeIds={[...list.map((p) => p.person_id), ...substitutes.map((s) => s.id)]}
              onSelect={(person) => {
                onAddSubstitute(person)
                setSearching(false)
              }}
            />
            <Button variant="ghost" className="self-start" onClick={() => setSearching(false)}>
              Abbrechen
            </Button>
          </div>
        ) : (
          <Button variant="outline" className="h-11 self-start sm:h-8" onClick={() => setSearching(true)} disabled={disabled}>
            <UserPlusIcon data-icon="inline-start" aria-hidden="true" />
            Person hinzufügen
          </Button>
        )}
      </fieldset>

      <fieldset className="flex flex-col gap-2">
        <legend className="mb-2 flex w-full items-baseline justify-between gap-3 font-medium">
          Teilnehmer:innen
          <span className="text-sm font-normal text-muted-foreground tabular-nums">{participantsChecked} ausgewählt</span>
        </legend>
        <ul className="flex flex-col divide-y rounded-xl border">
          {participants.map((p) => (
            <Row
              key={p.person_id}
              id={p.person_id}
              name={personName(p)}
              selected={checked.get(p.person_id)}
              locked={lockedIds.has(p.person_id)}
              settled={settledIds.has(p.person_id)}
              disabled={disabled}
              onToggle={(on) => onToggle(p, on)}
              onRole={onRole}
            />
          ))}
          {participants.length === 0 && (
            <li className="px-3 py-2.5 text-sm text-muted-foreground">An diesem Tag hat die Gruppe keine Teilnehmer:innen.</li>
          )}
        </ul>
      </fieldset>
    </div>
  )
}

function Row({
  id,
  name,
  badge,
  selected,
  withRole,
  locked,
  settled,
  disabled,
  onToggle,
  onRole,
}: {
  id: string
  name: string
  badge?: string
  selected: FormPerson | undefined
  withRole?: boolean
  locked: boolean
  settled: boolean
  disabled: boolean
  onToggle: (checked: boolean) => void
  onRole: (personId: string, role: Role) => void
}) {
  const inputId = `ez-att-${id}`
  return (
    <li className="flex flex-wrap items-center justify-between gap-2 pr-3">
      <label htmlFor={inputId} className="flex min-h-11 flex-1 cursor-pointer items-center gap-3 pl-3">
        <input
          id={inputId}
          type="checkbox"
          checked={!!selected}
          onChange={(e) => onToggle(e.target.checked)}
          disabled={disabled || locked || settled}
          className="size-5 shrink-0 accent-primary"
        />
        <span>{name}</span>
        {badge && <Badge variant="outline">{badge}</Badge>}
        {settled && <SettledBadge />}
      </label>
      {withRole && selected && (
        <select
          aria-label={`Rolle von ${name}`}
          value={selected.role}
          onChange={(e) => onRole(id, e.target.value as Role)}
          disabled={disabled || locked || settled}
          className={cn(selectClassName, 'sm:w-36')}
        >
          {(['trainer', 'helper'] as Role[]).map((r) => (
            <option key={r} value={r}>
              {ROLE_LABELS[r]}
            </option>
          ))}
        </select>
      )}
    </li>
  )
}

type EntryProps = {
  persons: FormPerson[]
  names: Record<string, string>
  defaultRole: Role
  lockedIds: Set<string>
  settledIds: Set<string>
  disabled: boolean
  onAdd: (person: ActivePerson) => void
  onChange: (personId: string, patch: Partial<FormPerson>) => void
  onRemove: (personId: string) => void
}

// T028 (US-EZ-09, -10, -20; R17, R20, R21): Personen eintragen bei Arbeitseinsatz, Kurs und Tour mit Rolle und Stand;
// keine Teilnehmer:innen. Personen aus der Planung (R25) behalten Rolle und bleiben in der Liste.
export function PersonenEintragen({ persons, names, defaultRole, lockedIds, settledIds, disabled, onAdd, onChange, onRemove }: EntryProps) {
  return (
    <div className="flex flex-col gap-3">
      {persons.length > 0 ? (
        <ul className="flex flex-col divide-y rounded-xl border">
          {persons.map((p) => {
            const name = names[p.person_id] ?? 'unbekannte Person'
            const settled = settledIds.has(p.person_id)
            const locked = lockedIds.has(p.person_id) || settled
            return (
              <li key={p.person_id} className="flex flex-col gap-2 px-3 py-2.5 sm:flex-row sm:items-center sm:justify-between">
                <span className="flex flex-wrap items-center gap-1.5 font-medium">
                  {name}
                  {lockedIds.has(p.person_id) && <Badge variant="outline">aus der Planung</Badge>}
                  {settled && <SettledBadge />}
                </span>
                <div className="flex flex-wrap items-center gap-2">
                  <select
                    aria-label={`Rolle von ${name}`}
                    value={p.role}
                    onChange={(e) => onChange(p.person_id, { role: e.target.value as Role })}
                    disabled={disabled || locked}
                    className={cn(selectClassName, 'sm:w-32')}
                  >
                    {(['trainer', 'helper'] as Role[]).map((r) => (
                      <option key={r} value={r}>
                        {ROLE_LABELS[r]}
                      </option>
                    ))}
                  </select>
                  <select
                    aria-label={`Stand von ${name}`}
                    value={p.status}
                    onChange={(e) => onChange(p.person_id, { status: e.target.value as AttendanceStatus })}
                    disabled={disabled || settled}
                    className={cn(selectClassName, 'sm:w-40')}
                  >
                    {(['registered', 'present', 'absent'] as AttendanceStatus[]).map((s) => (
                      <option key={s} value={s}>
                        {STATUS_LABELS[s]}
                      </option>
                    ))}
                  </select>
                  {!locked && (
                    <Button
                      variant="ghost"
                      size="icon"
                      aria-label={`${name} entfernen`}
                      onClick={() => onRemove(p.person_id)}
                      disabled={disabled}
                      className="size-11 sm:size-8"
                    >
                      <XIcon aria-hidden="true" />
                    </Button>
                  )}
                </div>
              </li>
            )
          })}
        </ul>
      ) : (
        <p className="text-sm text-muted-foreground">Noch keine Personen eingetragen.</p>
      )}
      <AktivenSuche
        label={`Person eintragen (${ROLE_LABELS[defaultRole]} vorbelegt)`}
        excludeIds={persons.map((p) => p.person_id)}
        onSelect={onAdd}
      />
    </div>
  )
}
