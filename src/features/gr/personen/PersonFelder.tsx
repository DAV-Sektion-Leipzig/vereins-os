import { MailIcon, PhoneIcon } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import type { Contact, NewPerson } from '@/features/gr/personen/data'

type Field = keyof NewPerson

const LABELS: Record<Field, string> = {
  first_name: 'Vorname',
  last_name: 'Nachname',
  preferred_name: 'Rufname',
  birth_date: 'Geburtsdatum',
  street: 'Straße und Hausnummer',
  postal_code: 'PLZ',
  city: 'Ort',
  phone_mobile: 'Telefon mobil',
  phone_landline: 'Telefon Festnetz',
  email: 'E-Mail',
  member_number: 'Mitgliedsnummer',
}

const TYPES: Partial<Record<Field, string>> = { birth_date: 'date', email: 'email', phone_mobile: 'tel', phone_landline: 'tel' }

/** Felder einer Person (GR spec.md 2.2); welche gezeigt werden, hängt von der Rolle ab. */
export function PersonFelder({
  idPrefix,
  value,
  onChange,
  fields,
  required = [],
}: {
  idPrefix: string
  value: NewPerson
  onChange: (next: NewPerson) => void
  fields: Field[]
  required?: Field[]
}) {
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      {fields.map((f) => (
        <div key={f} className={f === 'street' ? 'flex flex-col gap-2 sm:col-span-2' : 'flex flex-col gap-2'}>
          <Label htmlFor={`${idPrefix}-${f}`}>
            {LABELS[f]}
            {!required.includes(f) && <span className="font-normal text-muted-foreground"> (optional)</span>}
          </Label>
          <Input
            id={`${idPrefix}-${f}`}
            type={TYPES[f] ?? 'text'}
            value={value[f]}
            onChange={(e) => onChange({ ...value, [f]: e.target.value })}
            autoComplete="off"
            className={f === 'birth_date' ? 'sm:w-44' : undefined}
          />
        </div>
      ))}
    </div>
  )
}

/** Telefon als tel:-Link, E-Mail als mailto:-Link (spec.md 6), Trefferfläche ≥ 44 px auf dem Telefon. */
export function ContactLinks({ contact, showAddress = false }: { contact: Contact; showAddress?: boolean }) {
  const linkClass = 'inline-flex min-h-11 items-center gap-1.5 underline-offset-4 hover:underline sm:min-h-0'
  const address = [contact.street, [contact.postal_code, contact.city].filter(Boolean).join(' ')].filter(Boolean).join(', ')
  const items = [
    contact.phone_mobile && (
      <a key="m" href={`tel:${contact.phone_mobile.replace(/\s/g, '')}`} className={linkClass}>
        <PhoneIcon aria-hidden="true" className="size-4" />
        {contact.phone_mobile}
        <span className="text-muted-foreground">(mobil)</span>
      </a>
    ),
    contact.phone_landline && (
      <a key="l" href={`tel:${contact.phone_landline.replace(/\s/g, '')}`} className={linkClass}>
        <PhoneIcon aria-hidden="true" className="size-4" />
        {contact.phone_landline}
        <span className="text-muted-foreground">(Festnetz)</span>
      </a>
    ),
    contact.email && (
      <a key="e" href={`mailto:${contact.email}`} className={linkClass}>
        <MailIcon aria-hidden="true" className="size-4" />
        {contact.email}
      </a>
    ),
  ].filter(Boolean)
  return (
    <span className="flex flex-col gap-0.5 text-sm sm:flex-row sm:flex-wrap sm:gap-x-4">
      {items.length > 0 ? items : <span className="text-muted-foreground">keine Kontaktdaten</span>}
      {showAddress && address && <span className="text-muted-foreground">{address}</span>}
    </span>
  )
}
