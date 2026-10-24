import { useState } from 'react'
import { ArrowDownIcon, ArrowUpIcon, PlusIcon } from 'lucide-react'
import { Link } from 'react-router-dom'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import type { RelationRow } from '@/features/gr/personen/data'
import {
  choiceArgs,
  CONTACT_FIELDS,
  CONTACT_REQUIRED,
  GUARDIAN_FIELDS,
  GUARDIAN_REQUIRED,
} from '@/features/gr/personen/fields'
import { ContactLinks } from '@/features/gr/personen/PersonFelder'
import { PersonWahl } from '@/features/gr/personen/PersonWahl'
import { grRpc } from '@/features/gr/shared/rpc'
import { FormError } from '@/features/gr/shared/ui'
import { MESSAGES } from '@/lib/errors'
import { personName } from '@/lib/format'

type Props = { childId: string; editable: boolean; onChanged: () => void }

// T041 (US-GR-07, R3, R22, R26, A3): Erziehungsberechtigte (höchstens zwei), „Adresse übernehmen“, entfernen
export function ErziehungsberechtigteAbschnitt({ childId, guardians, editable, onChanged }: Props & { guardians: RelationRow[] }) {
  const [adding, setAdding] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function run(name: string, args: Record<string, unknown>, success?: string) {
    setError(null)
    const result = await grRpc(name, args)
    if (result.error !== null) return setError(result.error)
    if (success) toast.success(success)
    onChanged()
  }

  return (
    <div className="flex flex-col gap-3">
      {guardians.length === 0 ? (
        <p className="text-sm text-muted-foreground">Keine erziehungsberechtigte Person hinterlegt.</p>
      ) : (
        <ul className="flex flex-col divide-y rounded-xl border">
          {guardians.map((g) => (
            <li key={g.id} className="flex flex-col gap-2 px-4 py-3 sm:flex-row sm:items-start sm:justify-between">
              <span className="flex flex-col gap-1">
                <Link to={`/gr/personen/${g.person.id}`} className="font-medium underline-offset-4 hover:underline">
                  {personName(g.person)}
                </Link>
                <ContactLinks contact={g.person.contact} showAddress />
              </span>
              {editable && (
                <span className="flex flex-wrap gap-2">
                  <Button
                    variant="outline"
                    className="h-11 sm:h-8"
                    onClick={() => void run('gr_copy_address', { p_child: childId, p_from_guardian: g.person.id }, 'Adresse übernommen.')}
                  >
                    Adresse übernehmen
                  </Button>
                  <Button variant="ghost" className="h-11 sm:h-8" onClick={() => void run('gr_remove_guardian', { p_child: childId, p_guardian: g.person.id })}>
                    Entfernen
                  </Button>
                </span>
              )}
            </li>
          ))}
        </ul>
      )}
      <FormError text={error} />
      {editable && guardians.length < 2 && !adding && (
        <Button variant="outline" onClick={() => setAdding(true)} className="h-11 self-start sm:h-8">
          <PlusIcon data-icon="inline-start" aria-hidden="true" />
          Erziehungsberechtigte Person hinzufügen
        </Button>
      )}
      {editable && adding && (
        <div className="rounded-xl border p-4">
          <PersonWahl
            idPrefix="gr-guardian"
            fields={GUARDIAN_FIELDS}
            required={GUARDIAN_REQUIRED}
            validate={(v) => (GUARDIAN_REQUIRED.some((f) => !v[f].trim()) ? MESSAGES.grGuardianFieldsRequired : null)}
            submitLabel="Als erziehungsberechtigt hinzufügen"
            exclude={[childId, ...guardians.map((g) => g.person.id)]}
            onCancel={() => setAdding(false)}
            onChoose={async (choice) => {
              const result = await grRpc('gr_add_guardian', { p_child: childId, ...choiceArgs(choice) })
              if (result.error !== null) return result.error
              setAdding(false)
              onChanged()
              return null
            }}
          />
        </div>
      )}
    </div>
  )
}

// T041 (US-GR-09, R7, R23): Notfallkontakte mit Reihenfolge (1 = zuerst anrufen); Erziehungsberechtigte
// lassen sich mit einem Klick übernehmen
export function NotfallkontakteAbschnitt({
  childId,
  contacts,
  guardians,
  editable,
  onChanged,
}: Props & { contacts: RelationRow[]; guardians: RelationRow[] }) {
  const [adding, setAdding] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const quick = guardians.filter((g) => !contacts.some((c) => c.person.id === g.person.id))

  async function run(name: string, args: Record<string, unknown>) {
    setError(null)
    const result = await grRpc(name, args)
    if (result.error !== null) return setError(result.error)
    onChanged()
  }

  function move(index: number, delta: number) {
    const ids = contacts.map((c) => c.person.id)
    const [item] = ids.splice(index, 1)
    ids.splice(index + delta, 0, item)
    void run('gr_reorder_emergency_contacts', { p_child: childId, p_contact_ids: ids })
  }

  return (
    <div className="flex flex-col gap-3">
      {contacts.length > 0 && (
        <ol className="flex flex-col divide-y rounded-xl border">
          {contacts.map((c, i) => (
            <li key={c.id} className="flex flex-col gap-2 px-4 py-3 sm:flex-row sm:items-start sm:justify-between">
              <span className="flex flex-col gap-1">
                <span className="font-medium">
                  {i + 1}. {personName(c.person)}
                </span>
                <ContactLinks contact={c.person.contact} />
              </span>
              {editable && (
                <span className="flex flex-wrap gap-2">
                  <Button variant="ghost" size="icon" className="size-11 sm:size-8" disabled={i === 0} onClick={() => move(i, -1)} aria-label={`${personName(c.person)} nach oben`}>
                    <ArrowUpIcon aria-hidden="true" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="size-11 sm:size-8"
                    disabled={i === contacts.length - 1}
                    onClick={() => move(i, 1)}
                    aria-label={`${personName(c.person)} nach unten`}
                  >
                    <ArrowDownIcon aria-hidden="true" />
                  </Button>
                  <Button variant="ghost" className="h-11 sm:h-8" onClick={() => void run('gr_remove_emergency_contact', { p_child: childId, p_contact: c.person.id })}>
                    Entfernen
                  </Button>
                </span>
              )}
            </li>
          ))}
        </ol>
      )}
      <FormError text={error} />
      {editable && quick.length > 0 && (
        <span className="flex flex-wrap gap-2">
          {quick.map((g) => (
            <Button
              key={g.id}
              variant="outline"
              className="h-11 sm:h-8"
              onClick={() => void run('gr_add_emergency_contact', { p_child: childId, p_person_id: g.person.id, p_new_person: null })}
            >
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              {personName(g.person)} als Notfallkontakt
            </Button>
          ))}
        </span>
      )}
      {editable && !adding && (
        <Button variant="outline" onClick={() => setAdding(true)} className="h-11 self-start sm:h-8">
          <PlusIcon data-icon="inline-start" aria-hidden="true" />
          Notfallkontakt hinzufügen
        </Button>
      )}
      {editable && adding && (
        <div className="rounded-xl border p-4">
          <PersonWahl
            idPrefix="gr-contact"
            fields={CONTACT_FIELDS}
            required={CONTACT_REQUIRED}
            validate={(v) =>
              !v.first_name.trim() || !v.last_name.trim()
                ? MESSAGES.nameRequired
                : !v.phone_mobile.trim() && !v.phone_landline.trim() && !v.email.trim()
                  ? MESSAGES.grContactReachability
                  : null
            }
            submitLabel="Als Notfallkontakt hinzufügen"
            exclude={[childId, ...contacts.map((c) => c.person.id)]}
            onCancel={() => setAdding(false)}
            onChoose={async (choice) => {
              const result = await grRpc('gr_add_emergency_contact', { p_child: childId, ...choiceArgs(choice) })
              if (result.error !== null) return result.error
              setAdding(false)
              onChanged()
              return null
            }}
          />
        </div>
      )}
    </div>
  )
}
