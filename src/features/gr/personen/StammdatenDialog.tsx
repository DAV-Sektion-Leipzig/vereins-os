import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import type { NewPerson, PersonInfo } from '@/features/gr/personen/data'
import { PersonFelder } from '@/features/gr/personen/PersonFelder'
import { grRpc } from '@/features/gr/shared/rpc'
import { FormError } from '@/features/gr/shared/ui'

type Field = keyof NewPerson

// T041 (US-GR-07, R2, R7, R25, R26): Namen und Personenangaben ändern (gr_update_person). Die Änderung gilt in allen
// Modulen (eine Person). Geburtsdatum nur mit „Gruppen verwalten“.
export function StammdatenDialog({
  person,
  canManage,
  onClose,
  onDone,
}: {
  person: PersonInfo
  canManage: boolean
  onClose: () => void
  onDone: () => void
}) {
  const initial: NewPerson = {
    first_name: person.first_name,
    last_name: person.last_name,
    preferred_name: person.preferred_name ?? '',
    birth_date: person.birth_date ?? '',
    street: person.contact.street ?? '',
    postal_code: person.contact.postal_code ?? '',
    city: person.contact.city ?? '',
    phone_mobile: person.contact.phone_mobile ?? '',
    phone_landline: person.contact.phone_landline ?? '',
    email: person.contact.email ?? '',
    member_number: person.member_number ?? '',
  }
  const fields: Field[] = [
    'first_name',
    'last_name',
    'preferred_name',
    ...(canManage ? (['birth_date'] as Field[]) : []),
    'street',
    'postal_code',
    'city',
    'phone_mobile',
    'phone_landline',
    'email',
    'member_number',
  ]
  const [value, setValue] = useState(initial)
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    // nur geänderte Felder senden; das Geburtsdatum lässt sich nicht leeren
    const changed = Object.fromEntries(
      fields.filter((f) => value[f] !== initial[f] && !(f === 'birth_date' && value[f] === '')).map((f) => [f, value[f].trim()]),
    )
    if (Object.keys(changed).length === 0) return onClose()
    setPending(true)
    const result = await grRpc('gr_update_person', { p_person: person.id, p_data: changed })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    onDone()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Stammdaten ändern</DialogTitle>
        </DialogHeader>
        <form id="gr-person-form" onSubmit={onSubmit} noValidate>
          <PersonFelder idPrefix="gr-person" value={value} onChange={setValue} fields={fields} required={['first_name', 'last_name']} />
        </form>
        <FormError text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="submit" form="gr-person-form" disabled={pending}>
            {pending ? 'Speichern …' : 'Speichern'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
