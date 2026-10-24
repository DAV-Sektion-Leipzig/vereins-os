// Personendaten in Gruppen (US-GR-06–14): eine Person mit Personenangaben (Eigenschaften birth_date, contact,
// member), Erziehungsberechtigten, Notfallkontakten, Teilnahmen mit Verträgen, Fotoerlaubnis, Einwilligung,
// Gesundheitsangaben und Funktionen in Gruppen. Was sichtbar ist, entscheidet die RLS (spec.md 3).
import type { LoaderFunctionArgs } from 'react-router-dom'
import { loadGrAccess } from '@/features/gr/access'
import type { MembershipRow } from '@/features/gr/gruppen/detail'
import { supabase } from '@/lib/supabase'

export type PersonCore = { id: string; first_name: string; preferred_name: string | null; last_name: string }

export type Contact = {
  street?: string
  postal_code?: string
  city?: string
  phone_mobile?: string
  phone_landline?: string
  email?: string
}

export type PersonInfo = PersonCore & {
  contact: Contact
  /** null, wenn nicht lesbar (Lesestufe nur Geschäftsstelle und Admin) oder nicht erfasst */
  birth_date: string | null
  member_number: string | null
}

export type ContractRow = {
  id: string
  membership_id: string
  holder_person_id: string
  starts_on: string
  cancelled_on: string | null
  ends_on: string | null
  account_holder: string
  iban: string
  mandate_reference: string
  mandate_signed_on: string
  purpose: string
  monthly_amount: number
}

export type ConsentRow = { id: number; granted: boolean; effective_on: string; created_at: string; created_by: string | null }

export type HealthHistoryRow = { id: number; note: string; valid_since: string; replaced_at: string }

export type RelationRow = { id: string; person: PersonInfo; sort_order?: number }

export type FunctionOfPerson = {
  id: string
  function: string
  group_id: string
  group_name: string
  valid_from: string
  valid_to: string | null
}

export type GrPerson = {
  person: PersonInfo
  pending: { group_id: string; group_name: string } | null
  memberships: (MembershipRow & { group_name: string })[]
  contracts: ContractRow[]
  guardians: RelationRow[]
  emergencyContacts: RelationRow[]
  /** Kinder, für die die Person erziehungsberechtigt bzw. Notfallkontakt ist */
  guardianOf: PersonCore[]
  emergencyContactOf: PersonCore[]
  functions: FunctionOfPerson[]
  photoConsents: ConsentRow[]
  /** null: nicht lesbar (kein Recht oder ohne Einwilligung, R11, R24) */
  healthConsents: ConsentRow[]
  healthNote: { note: string; updated_at: string } | null
  healthHistory: HealthHistoryRow[]
  needsGuardian: boolean | null
}

export type GrPersonResult = { state: 'ok'; data: GrPerson } | { state: 'not_found' | 'failed' }

export const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

const PERSON_FIELDS = 'id, first_name, preferred_name, last_name'

type PropRow = { person_id: string; field_values: Record<string, unknown>; valid_from: string; type: { system_key: string } }

/** Personenangaben mehrerer Personen (aktuelle Eigenschaften birth_date, contact, member). */
export async function loadPersonInfos(persons: PersonCore[]): Promise<PersonInfo[] | null> {
  if (persons.length === 0) return []
  const { data, error } = await supabase
    .from('ea_properties')
    .select('person_id, field_values, valid_from, valid_to, type:ea_property_types!inner(system_key)')
    .in(
      'person_id',
      persons.map((p) => p.id),
    )
    .in('type.system_key', ['birth_date', 'contact', 'member'])
    .or(`valid_to.is.null,valid_to.gte.${new Date().toISOString().slice(0, 10)}`)
    .order('valid_from', { ascending: false })
  if (error) return null
  const rows = (data ?? []) as unknown as PropRow[]
  return persons.map((p) => {
    const own = rows.filter((r) => r.person_id === p.id)
    const pick = (key: string) => own.find((r) => r.type.system_key === key)?.field_values
    return {
      ...p,
      contact: (pick('contact') ?? {}) as Contact,
      birth_date: (pick('birth_date')?.date as string | undefined) ?? null,
      member_number: (pick('member')?.member_number as string | undefined) ?? null,
    }
  })
}

type GuardianQuery = { id: string; sort_order?: number; person: PersonCore | null }

export async function loadGrPerson(personId: string): Promise<GrPersonResult> {
  if (!UUID.test(personId)) return { state: 'not_found' }
  const [person, pending, memberships, guardians, contacts, guardianOf, contactOf, functions, photo, healthConsents, healthNote, healthHistory, needsGuardian] =
    await Promise.all([
      supabase.from('ea_persons').select(PERSON_FIELDS).eq('id', personId).eq('kind', 'human').maybeSingle(),
      supabase.from('gr_pending_admissions').select('group_id, group:gr_groups(name)').eq('person_id', personId).maybeSingle(),
      supabase.from('gr_v_memberships').select('*').eq('person_id', personId).order('joined_on', { ascending: false }),
      supabase
        .from('gr_guardians')
        .select(`id, person:ea_persons!gr_guardians_guardian_person_id_fkey(${PERSON_FIELDS})`)
        .eq('child_person_id', personId)
        .order('created_at'),
      supabase
        .from('gr_emergency_contacts')
        .select(`id, sort_order, person:ea_persons!gr_emergency_contacts_contact_person_id_fkey(${PERSON_FIELDS})`)
        .eq('child_person_id', personId)
        .order('sort_order'),
      supabase
        .from('gr_guardians')
        .select(`id, person:ea_persons!gr_guardians_child_person_id_fkey(${PERSON_FIELDS})`)
        .eq('guardian_person_id', personId),
      supabase
        .from('gr_emergency_contacts')
        .select(`id, person:ea_persons!gr_emergency_contacts_child_person_id_fkey(${PERSON_FIELDS})`)
        .eq('contact_person_id', personId),
      supabase
        .from('ea_properties')
        .select('id, field_values, related_group_id, valid_from, valid_to, group:gr_groups(name), type:ea_property_types!inner(system_key)')
        .eq('person_id', personId)
        .eq('type.system_key', 'group_function')
        .order('valid_from', { ascending: false }),
      supabase.from('gr_photo_consents').select('id, granted, effective_on, created_at, created_by').eq('person_id', personId),
      supabase.from('gr_health_consents').select('id, granted, effective_on, created_at, created_by').eq('person_id', personId),
      supabase.from('gr_health_notes').select('note, updated_at').eq('person_id', personId).maybeSingle(),
      supabase.from('gr_health_note_history').select('id, note, valid_since, replaced_at').eq('person_id', personId).order('replaced_at', { ascending: false }),
      supabase.rpc('gr_needs_guardian', { p_person: personId }),
    ])

  const failed = [person, pending, memberships, guardians, contacts, guardianOf, contactOf, functions, photo, healthConsents, healthNote, healthHistory].some(
    (r) => r.error,
  )
  if (failed) return { state: 'failed' }
  if (!person.data) return { state: 'not_found' }

  const membershipRows = (memberships.data ?? []) as MembershipRow[]
  const [contracts, groups] =
    membershipRows.length === 0
      ? [{ data: [], error: null }, { data: [], error: null }]
      : await Promise.all([
          supabase
            .from('gr_contracts')
            .select('*')
            .in(
              'membership_id',
              membershipRows.map((m) => m.membership_id),
            )
            .order('starts_on'),
          supabase
            .from('gr_groups')
            .select('id, name')
            .in('id', [...new Set(membershipRows.map((m) => m.group_id))]),
        ])
  if (contracts.error || groups.error) return { state: 'failed' }
  const groupName = (id: string) => ((groups.data ?? []) as { id: string; name: string }[]).find((g) => g.id === id)?.name ?? ''

  const guardianRows = ((guardians.data ?? []) as unknown as GuardianQuery[]).filter((g) => g.person)
  const contactRows = ((contacts.data ?? []) as unknown as GuardianQuery[]).filter((g) => g.person)
  const infos = await loadPersonInfos([person.data as PersonCore, ...guardianRows.map((g) => g.person!), ...contactRows.map((c) => c.person!)])
  if (!infos) return { state: 'failed' }
  const info = (id: string) => infos.find((i) => i.id === id)!

  const byNewest = (a: ConsentRow, b: ConsentRow) =>
    b.effective_on.localeCompare(a.effective_on) || b.created_at.localeCompare(a.created_at) || b.id - a.id
  const pendingRow = pending.data as unknown as { group_id: string; group: { name: string } | null } | null

  return {
    state: 'ok',
    data: {
      person: info(personId),
      pending: pendingRow ? { group_id: pendingRow.group_id, group_name: pendingRow.group?.name ?? '' } : null,
      memberships: membershipRows.map((m) => ({ ...m, group_name: groupName(m.group_id) })),
      contracts: (contracts.data ?? []) as ContractRow[],
      guardians: guardianRows.map((g) => ({ id: g.id, person: info(g.person!.id) })),
      emergencyContacts: contactRows.map((c) => ({ id: c.id, sort_order: c.sort_order, person: info(c.person!.id) })),
      guardianOf: ((guardianOf.data ?? []) as unknown as GuardianQuery[]).flatMap((g) => (g.person ? [g.person] : [])),
      emergencyContactOf: ((contactOf.data ?? []) as unknown as GuardianQuery[]).flatMap((g) => (g.person ? [g.person] : [])),
      functions: (
        (functions.data ?? []) as unknown as {
          id: string
          field_values: { function?: string }
          related_group_id: string
          valid_from: string
          valid_to: string | null
          group: { name: string } | null
        }[]
      ).map((f) => ({
        id: f.id,
        function: f.field_values.function ?? '',
        group_id: f.related_group_id,
        group_name: f.group?.name ?? '',
        valid_from: f.valid_from,
        valid_to: f.valid_to,
      })),
      photoConsents: ((photo.data ?? []) as ConsentRow[]).sort(byNewest),
      healthConsents: ((healthConsents.data ?? []) as ConsentRow[]).sort(byNewest),
      healthNote: healthNote.data as GrPerson['healthNote'],
      healthHistory: (healthHistory.data ?? []) as HealthHistoryRow[],
      needsGuardian: needsGuardian.error ? null : (needsGuardian.data as boolean | null),
    },
  }
}

/** Aktueller Stand einer Einwilligung; ohne Eintrag „nein“ (R12). */
export function currentConsent(rows: ConsentRow[]): boolean {
  return rows[0]?.granted ?? false
}

/** Suche nach sichtbaren Personen (RLS) für „vorhandene Person wählen“. */
export async function searchPersons(term: string): Promise<PersonCore[] | null> {
  const q = term.trim().replace(/["\\,()]/g, '')
  if (q.length < 2) return []
  const like = `"%${q}%"`
  const { data, error } = await supabase
    .from('ea_v_persons')
    .select(PERSON_FIELDS)
    .or(`first_name.ilike.${like},preferred_name.ilike.${like},last_name.ilike.${like}`)
    .order('last_name')
    .order('first_name')
    .limit(20)
  return error ? null : ((data ?? []) as PersonCore[])
}

export type NewPerson = {
  first_name: string
  last_name: string
  preferred_name: string
  birth_date: string
  street: string
  postal_code: string
  city: string
  phone_mobile: string
  phone_landline: string
  email: string
  member_number: string
}

export const EMPTY_PERSON: NewPerson = {
  first_name: '',
  last_name: '',
  preferred_name: '',
  birth_date: '',
  street: '',
  postal_code: '',
  city: '',
  phone_mobile: '',
  phone_landline: '',
  email: '',
  member_number: '',
}

/** Loader von /gr/personen/:id (T038). */
export async function loadPersonPage({ params }: LoaderFunctionArgs): Promise<GrPersonResult> {
  await loadGrAccess()
  return loadGrPerson(params.id ?? '')
}
