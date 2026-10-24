// Feldlisten je Rolle (GR spec.md 2.2, R2, R7, R26) und Umwandlung in die Parameter der Gruppen-Funktionen.
import type { NewPerson } from '@/features/gr/personen/data'

type Field = keyof NewPerson

export type PersonChoice = { personId: string } | { newPerson: Record<string, string> }

export const PARTICIPANT_FIELDS: Field[] = [
  'first_name',
  'last_name',
  'preferred_name',
  'birth_date',
  'street',
  'postal_code',
  'city',
  'phone_mobile',
  'phone_landline',
  'email',
  'member_number',
]
export const PARTICIPANT_REQUIRED: Field[] = ['first_name', 'last_name', 'birth_date', 'street', 'postal_code', 'city']
export const GUARDIAN_FIELDS: Field[] = ['first_name', 'last_name', 'street', 'postal_code', 'city', 'phone_mobile', 'phone_landline', 'email']
export const GUARDIAN_REQUIRED: Field[] = ['first_name', 'last_name', 'street', 'postal_code', 'city']
export const CONTACT_FIELDS: Field[] = ['first_name', 'last_name', 'phone_mobile', 'phone_landline', 'email']
export const CONTACT_REQUIRED: Field[] = ['first_name', 'last_name']

/** Leere Felder weglassen (die Datenbank behandelt leere Strings als null). */
export function toPayload(value: NewPerson, fields: Field[]): Record<string, string> {
  return Object.fromEntries(fields.filter((f) => value[f].trim() !== '').map((f) => [f, value[f].trim()]))
}


/** Parameter für die Gruppen-Funktionen mit p_person_id bzw. p_new_person. */
export function choiceArgs(choice: PersonChoice): { p_person_id: string | null; p_new_person: Record<string, string> | null } {
  return 'personId' in choice ? { p_person_id: choice.personId, p_new_person: null } : { p_person_id: null, p_new_person: choice.newPerson }
}

export type ContractForm = {
  holder_person_id: string
  starts_on: string
  account_holder: string
  iban: string
  mandate_reference: string
  mandate_signed_on: string
  purpose: string
  monthly_amount: string
}

export const EMPTY_CONTRACT: ContractForm = {
  holder_person_id: '',
  starts_on: '',
  account_holder: '',
  iban: '',
  mandate_reference: '',
  mandate_signed_on: '',
  purpose: '',
  monthly_amount: '',
}

/** Für die Datenbank: Betrag mit Punkt, leere Felder bleiben leer (R27 prüft die Datenbank). */
export function contractPayload(value: ContractForm): Record<string, string | number> {
  const amount = Number(value.monthly_amount.replace(',', '.'))
  return {
    ...value,
    monthly_amount: value.monthly_amount.trim() === '' || Number.isNaN(amount) ? '' : amount,
  }
}
