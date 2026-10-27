// Übersicht der Aktiven (US-EA-02, US-EA-03; T034). Welche Personen sichtbar sind, entscheidet die RLS
// (R32 AD); ea_volunteer_list filtert nur innerhalb davon. Filter und Seite stehen in der URL (A5).
import { redirect, type LoaderFunctionArgs } from 'react-router-dom'
import { PAGE_SIZE } from '@/components/Pagination'
import { loadPersonProperties, loadUserNames, type PropertiesData } from '@/features/ad/personen/data'
import { loadEaAccess, type EaAccess } from '@/features/ea/access'
import type { ExpiryStatus } from '@/features/ea/shared/AblaufBadge'
import { supabase } from '@/lib/supabase'

export type VolunteerStatus = 'active' | 'dormant' | 'left'

export const VOLUNTEER_STATUS_LABELS: Record<VolunteerStatus, string> = {
  active: 'aktiv',
  dormant: 'ruhend',
  left: 'ausgeschieden',
}

/** Ohne Statusfilter: „aktiv“ und „ruhend“ (R1). */
export const DEFAULT_STATUS: VolunteerStatus[] = ['active', 'dormant']

export const EXPIRY_FILTERS: Record<ExpiryStatus, string> = {
  expired: 'abgelaufen',
  expiring: 'läuft in ≤ 3 Monaten ab',
  valid: 'gültig',
  none: 'ohne Ablauf',
}

export type VolunteerRow = {
  id: string
  first_name: string
  preferred_name: string | null
  last_name: string
  volunteer_status: VolunteerStatus
  volunteer_status_since: string
  referate: string[]
  functions: string[]
  positions: string[]
  license_codes: string[]
  worst_expiry: ExpiryStatus
  trainer_without_license: boolean
  total_count: number
  /** Abgelaufene und bald ablaufende Eigenschaften aus ea_v_expiry, abgelaufene zuerst */
  expiries: ExpiryItem[]
}

export type ExpiryKind = 'license' | 'qualification' | 'police_clearance'

export type ExpiryItem = {
  propertyId: string
  kind: ExpiryKind
  /** Kürzel, sonst Bezeichnung der Qualifikationsart; beim Führungszeugnis null */
  code: string | null
  validUntil: string
  status: 'expired' | 'expiring'
}

export type VolunteerFilter = {
  q: string
  status: VolunteerStatus[]
  referate: string[]
  func: string
  position: string
  gremium: string
  qualification: string
  discipline: string
  expiry: ExpiryStatus | ''
  withoutLicense: boolean
  withoutAssignment: boolean
  page: number
}

export type Option = { id: string; name: string }
export type QualificationOption = { id: string; code: string | null; name: string; discipline: string }

export type FilterOptions = {
  /** Auswählbare Referate: Referent:in nur die eigenen (US-EA-03 AK4). */
  referate: Option[]
  /** Nur mit verwalten (US-EA-03 AK4). */
  gremien: Option[] | null
  functions: string[]
  positions: string[]
  qualificationTypes: QualificationOption[]
  disciplines: string[]
  /** „ausgeschieden“ nur mit verwalten (R1). */
  statuses: VolunteerStatus[]
}

export type VolunteersResult = {
  filter: VolunteerFilter
  options: FilterOptions
  rows: VolunteerRow[]
  total: number
  failed: boolean
}

/** Referent:in: Reichweite nur Referat – Referatsfilter eingeschränkt und vorbelegt (US-EA-03 AK4). */
export function restrictedReferate(access: EaAccess): string[] | null {
  return !access.canManage && !access.canEdit && access.myReferate.length > 0 ? access.myReferate : null
}

export function readFilter(url: URL, access?: EaAccess): VolunteerFilter {
  const p = url.searchParams
  const allowedStatus: VolunteerStatus[] = access?.canManage ? ['active', 'dormant', 'left'] : DEFAULT_STATUS
  const status = p.getAll('status').filter((s): s is VolunteerStatus => (allowedStatus as string[]).includes(s))
  const own = access ? restrictedReferate(access) : null
  const referate = p.getAll('referat').filter((id) => !own || own.includes(id))
  const expiry = p.get('ablauf') ?? ''
  const page = Number.parseInt(p.get('seite') ?? '1', 10)
  return {
    q: (p.get('q') ?? '').trim(),
    status: status.length > 0 ? status : DEFAULT_STATUS,
    referate: referate.length > 0 ? referate : (own ?? []),
    func: p.get('funktion') ?? '',
    position: p.get('amt') ?? '',
    gremium: access && !access.canManage ? '' : (p.get('gremium') ?? ''),
    qualification: p.get('qualifikation') ?? '',
    discipline: p.get('sparte') ?? '',
    expiry: expiry in EXPIRY_FILTERS ? (expiry as ExpiryStatus) : '',
    withoutLicense: p.get('ohne_lizenz') === '1',
    withoutAssignment: p.get('ohne_zuordnung') === '1',
    page: Number.isFinite(page) && page > 0 ? page : 1,
  }
}

export function filterHref(filter: VolunteerFilter, page = filter.page): string {
  const p = new URLSearchParams()
  if (filter.q) p.set('q', filter.q)
  if (filter.status.join() !== DEFAULT_STATUS.join()) filter.status.forEach((s) => p.append('status', s))
  filter.referate.forEach((id) => p.append('referat', id))
  if (filter.func) p.set('funktion', filter.func)
  if (filter.position) p.set('amt', filter.position)
  if (filter.gremium) p.set('gremium', filter.gremium)
  if (filter.qualification) p.set('qualifikation', filter.qualification)
  if (filter.discipline) p.set('sparte', filter.discipline)
  if (filter.expiry) p.set('ablauf', filter.expiry)
  if (filter.withoutLicense) p.set('ohne_lizenz', '1')
  if (filter.withoutAssignment) p.set('ohne_zuordnung', '1')
  if (page > 1) p.set('seite', String(page))
  const s = p.toString()
  return s ? `/ea/aktive?${s}` : '/ea/aktive'
}

/** Filter gesetzt, die über die Vorbelegung hinausgehen (für „Filter zurücksetzen“). */
export function hasActiveFilter(filter: VolunteerFilter, access: EaAccess): boolean {
  const own = restrictedReferate(access) ?? []
  return (
    filter.q !== '' ||
    filter.status.join() !== DEFAULT_STATUS.join() ||
    filter.referate.join() !== own.join() ||
    filter.func !== '' ||
    filter.position !== '' ||
    filter.gremium !== '' ||
    filter.qualification !== '' ||
    filter.discipline !== '' ||
    filter.expiry !== '' ||
    filter.withoutLicense ||
    filter.withoutAssignment
  )
}

type ChoiceType = { system_key: string; ea_property_fields: { key: string; choice_values: string[] | null }[] }

function choices(types: ChoiceType[], systemKey: 'function' | 'position'): string[] {
  const type = types.find((t) => t.system_key === systemKey)
  return type?.ea_property_fields.find((f) => f.key === systemKey)?.choice_values ?? []
}

async function loadOptions(access: EaAccess, selectedQualification: string): Promise<FilterOptions> {
  const [referate, gremien, types, qualifications, used] = await Promise.all([
    supabase.from('ea_referate').select('id, name').eq('is_active', true).order('sort_order'),
    access.canManage
      ? supabase.from('ea_gremien').select('id, name').eq('is_active', true).order('sort_order')
      : Promise.resolve({ data: null }),
    supabase
      .from('ea_property_types')
      .select('system_key, ea_property_fields(key, choice_values)')
      .in('system_key', ['function', 'position']),
    supabase.from('ad_qualification_types').select('id, code, name, discipline').order('discipline').order('name'),
    // Nur Arten anbieten, die bei sichtbaren Aktiven aktuell vergeben sind (RLS von ea_v_expiry entscheidet)
    supabase.from('ea_v_expiry').select('qualification_type_id').in('kind', ['license', 'qualification']),
  ])

  const own = restrictedReferate(access)
  const allReferate = (referate.data ?? []) as Option[]
  const usedIds = new Set(
    ((used.data ?? []) as { qualification_type_id: string | null }[]).map((r) => r.qualification_type_id),
  )
  // Die gewählte Art bleibt wählbar, auch wenn sie nicht (mehr) vergeben ist, damit der Filter sichtbar bleibt
  const qualificationTypes = ((qualifications.data ?? []) as QualificationOption[]).filter(
    (q) => usedIds.has(q.id) || q.id === selectedQualification,
  )
  const typeRows = (types.data ?? []) as ChoiceType[]

  return {
    referate: own ? allReferate.filter((r) => own.includes(r.id)) : allReferate,
    gremien: gremien.data ? (gremien.data as Option[]) : null,
    functions: choices(typeRows, 'function'),
    positions: choices(typeRows, 'position'),
    qualificationTypes,
    disciplines: [...new Set(qualificationTypes.map((q) => q.discipline))],
    statuses: access.canManage ? ['active', 'dormant', 'left'] : DEFAULT_STATUS,
  }
}

export async function loadVolunteers({ request }: LoaderFunctionArgs): Promise<VolunteersResult> {
  // Rechte vor jeder Datenabfrage (US-EA-01 AK4)
  const access = await loadEaAccess()
  const filter = readFilter(new URL(request.url), access)

  const [list, options] = await Promise.all([
    supabase.rpc('ea_volunteer_list', {
      p_search: filter.q || null,
      p_status: filter.status,
      p_referate: filter.referate.length > 0 ? filter.referate : null,
      p_function: filter.func || null,
      p_position: filter.position || null,
      p_gremium: filter.gremium || null,
      p_qualification_type: filter.qualification || null,
      p_discipline: filter.discipline || null,
      p_expiry: filter.expiry ? [filter.expiry] : null,
      p_trainer_without_license: filter.withoutLicense,
      p_without_assignment: filter.withoutAssignment,
      p_limit: PAGE_SIZE,
      p_offset: (filter.page - 1) * PAGE_SIZE,
    }),
    loadOptions(access, filter.qualification),
  ])

  if (list.error || !Array.isArray(list.data)) return { filter, options, rows: [], total: 0, failed: true }
  const listed = list.data as Omit<VolunteerRow, 'expiries'>[]
  const expiries = await loadExpiries(listed.map((r) => r.id))
  if (!expiries) return { filter, options, rows: [], total: 0, failed: true }
  const rows = listed.map((r) => ({ ...r, expiries: expiries.get(r.id) ?? [] }))
  return { filter, options, rows, total: rows[0]?.total_count ?? 0, failed: false }
}

type ExpiryViewRow = {
  property_id: string
  person_id: string
  kind: ExpiryKind
  qualification_code: string | null
  qualification_name: string | null
  valid_until: string
  expiry_status: 'expired' | 'expiring'
}

/** Was abgelaufen ist oder bald abläuft, je Person der Seite (RLS von ea_v_expiry; Referent:in ohne Führungszeugnis). */
async function loadExpiries(personIds: string[]): Promise<Map<string, ExpiryItem[]> | null> {
  const byPerson = new Map<string, ExpiryItem[]>()
  if (personIds.length === 0) return byPerson
  const { data, error } = await supabase
    .from('ea_v_expiry')
    .select('property_id, person_id, kind, qualification_code, qualification_name, valid_until, expiry_status')
    .in('person_id', personIds)
    .in('expiry_status', ['expired', 'expiring'])
  if (error || !data) return null
  const items = (data as ExpiryViewRow[]).toSorted(
    (a, b) =>
      Number(b.expiry_status === 'expired') - Number(a.expiry_status === 'expired') ||
      a.valid_until.localeCompare(b.valid_until),
  )
  for (const e of items) {
    const item: ExpiryItem = {
      propertyId: e.property_id,
      kind: e.kind,
      code: e.qualification_code ?? e.qualification_name,
      validUntil: e.valid_until,
      status: e.expiry_status,
    }
    byPerson.set(e.person_id, [...(byPerson.get(e.person_id) ?? []), item])
  }
  return byPerson
}

// --- Person im Detail (US-EA-04, US-EA-11; T038)

export type VolunteerPerson = {
  id: string
  first_name: string
  preferred_name: string | null
  last_name: string
  volunteer_status: VolunteerStatus | null
  volunteer_status_since: string | null
}

export type StatusHistoryEntry = {
  id: number
  status: VolunteerStatus
  valid_from: string
  set_at: string
  set_by: string | null
}

export type ExpiryRow = {
  property_id: string
  kind: 'license' | 'qualification' | 'police_clearance'
  valid_until: string | null
  expiry_status: ExpiryStatus
}

export type VolunteerDetailResult =
  | { state: 'not_found' }
  | { state: 'failed' }
  | {
      state: 'ok'
      person: VolunteerPerson
      history: StatusHistoryEntry[]
      /** Anzeigename je Auth-Nutzer (gesetzt von) */
      historyNames: Record<string, string>
      properties: PropertiesData | null
      /** Ablaufstatus je Eigenschaft aus ea_v_expiry (nur lesbare, aktuelle Eigenschaften aktiver und ruhender Personen) */
      expiry: Record<string, ExpiryStatus>
      trainerWithoutLicense: boolean
      /** Schreibrecht je Eigenschaft nach ea_property_writable (T042) */
      writable: Record<string, boolean>
      /** Arten für „Eigenschaft hinzufügen“: schreibbar, Referent:in nur Lesestufe „alle“ (US-EA-06 AK5) */
      addableTypeIds: string[]
      /** Referent:in: nur eigene Referate im Bezug (US-EA-06 AK4) */
      restrictReferate: string[] | null
    }

export const NOT_FOUND_MESSAGE = 'Diese Person wurde nicht gefunden oder du hast keine Rechte.'

const isoToday = () => new Date().toISOString().slice(0, 10)

/** R14: aktuelle Funktion Trainer:in und keine Lizenz mit „gültig bis“ ≥ heute. */
function isTrainerWithoutLicense(properties: PropertiesData, expiry: ExpiryRow[]): boolean {
  const today = isoToday()
  const functionType = properties.types.find((t) => t.system_key === 'function')
  const isTrainer = properties.properties.some(
    (p) =>
      p.property_type_id === functionType?.id &&
      p.field_values.function === 'Trainer:in' &&
      p.valid_from <= today &&
      (!p.valid_to || p.valid_to >= today),
  )
  return isTrainer && !expiry.some((e) => e.kind === 'license' && e.valid_until !== null && e.valid_until >= today)
}

async function isWritable(typeId: string, personId: string, referatId: string | null): Promise<boolean> {
  const { data, error } = await supabase.rpc('ea_property_writable', {
    p_property_type: typeId,
    p_person: personId,
    p_referat: referatId,
  })
  return !error && data === true
}

/**
 * Schreibrechte für das Detail (T042). Die Datenbank entscheidet (ea_property_writable, R12, R41 AD);
 * das Frontend blendet nur Knöpfe aus. Eine Art ist hinzufügbar, wenn sie ohne Bezug oder mit einem
 * eigenen Referat schreibbar ist.
 */
async function loadWriteRights(personId: string, properties: PropertiesData, access: EaAccess) {
  const own = restrictedReferate(access)
  const candidates = properties.types.filter((t) => (own ? t.read_level === 'all' : true) && t.relation_kind !== 'group')
  const [perProperty, perType] = await Promise.all([
    Promise.all(
      properties.properties.map(async (p) => [p.id, await isWritable(p.property_type_id, personId, p.related_referat_id)] as const),
    ),
    Promise.all(
      candidates.map(async (t) => {
        if (await isWritable(t.id, personId, null)) return t.id
        if (t.relation_kind === 'referat' && own?.length && (await isWritable(t.id, personId, own[0]))) return t.id
        return null
      }),
    ),
  ])
  return {
    writable: Object.fromEntries(perProperty),
    addableTypeIds: perType.filter((id): id is string => id !== null),
    restrictReferate: own,
  }
}

export async function loadVolunteerDetail({ params }: LoaderFunctionArgs): Promise<VolunteerDetailResult> {
  // Rechte vor jeder Datenabfrage (US-EA-01 AK4)
  const access = await loadEaAccess()
  const id = params.id!

  const [person, history, properties, expiry] = await Promise.all([
    supabase
      .from('ea_persons')
      .select('id, first_name, preferred_name, last_name, volunteer_status, volunteer_status_since')
      .eq('id', id)
      .maybeSingle(),
    supabase.from('ea_volunteer_status_history').select('id, status, valid_from, set_at, set_by').eq('person_id', id).order('set_at', { ascending: false }),
    loadPersonProperties(id, 'EA'),
    supabase.from('ea_v_expiry').select('property_id, kind, valid_until, expiry_status').eq('person_id', id),
  ])

  // Ungültige ID (22P02) wie eine nicht lesbare Person behandeln (US-EA-04 AK5)
  if (person.error?.code === '22P02') return { state: 'not_found' }
  if (person.error || history.error || expiry.error) return { state: 'failed' }
  if (!person.data) return { state: 'not_found' }

  const entries = history.data as StatusHistoryEntry[]
  const expiryRows = expiry.data as ExpiryRow[]
  const [historyNames, rights] = await Promise.all([
    loadUserNames(entries.map((h) => h.set_by ?? '')),
    properties
      ? loadWriteRights(id, properties, access)
      : Promise.resolve({ writable: {}, addableTypeIds: [], restrictReferate: restrictedReferate(access) }),
  ])
  return {
    state: 'ok',
    person: person.data as VolunteerPerson,
    history: entries,
    historyNames,
    ...rights,
    properties,
    expiry: Object.fromEntries(expiryRows.map((e) => [e.property_id, e.expiry_status])),
    trainerWithoutLicense: properties ? isTrainerWithoutLicense(properties, expiryRows) : false,
  }
}

// --- Person anlegen, Rückkehr und Übernahme (US-EA-05, US-EA-10; T040, T041)

export type AssignmentType = { id: string; systemKey: 'function' | 'position'; name: string; values: string[] }

export type NewVolunteerData = {
  /** Funktion und Amt (System-Eigenschaftsarten) mit ihren Auswahlwerten */
  types: AssignmentType[]
  /** Auswählbare Referate: Referent:in nur die eigenen */
  referate: Option[]
  /** Referent:in: Zuordnung in einem eigenen Referat ist Pflicht (R3) */
  referatRequired: boolean
}

type AssignmentTypeRow = {
  id: string
  name: string
  system_key: 'function' | 'position'
  ea_property_fields: { key: string; choice_values: string[] | null }[]
}

export async function loadNewVolunteer(): Promise<NewVolunteerData> {
  const access = await loadEaAccess()
  // Anlegen mit EA ≥ bearbeiten (alle) oder in eigenen Referaten (US-EA-05 AK6)
  if (!access.canEdit && access.myReferate.length === 0) throw redirect('/kein-zugriff')

  const [types, referate] = await Promise.all([
    supabase
      .from('ea_property_types')
      .select('id, name, system_key, ea_property_fields(key, choice_values)')
      .in('system_key', ['function', 'position']),
    supabase.from('ea_referate').select('id, name').eq('is_active', true).order('sort_order'),
  ])
  const own = restrictedReferate(access)
  const allReferate = (referate.data ?? []) as Option[]

  return {
    types: ((types.data ?? []) as AssignmentTypeRow[])
      .map((t) => ({
        id: t.id,
        systemKey: t.system_key,
        name: t.name,
        values: t.ea_property_fields.find((f) => f.key === t.system_key)?.choice_values ?? [],
      }))
      // Funktion vor Amt
      .sort((a, b) => Number(a.systemKey !== 'function') - Number(b.systemKey !== 'function')),
    referate: own ? allReferate.filter((r) => own.includes(r.id)) : allReferate,
    referatRequired: own !== null,
  }
}

export type VolunteerInput = {
  first: string
  preferred: string
  last: string
  /** Erste Zuordnung (Funktion oder Amt); leer = ohne Zuordnung (nur mit Reichweite alle, US-EA-05 AK3) */
  typeId: string
  systemKey: 'function' | 'position' | ''
  value: string
  referatId: string
  since: string
}

function assignmentArgs(input: VolunteerInput) {
  const withAssignment = input.typeId !== '' && input.systemKey !== ''
  return {
    p_property_type: withAssignment ? input.typeId : null,
    p_referat: withAssignment && input.referatId ? input.referatId : null,
    p_field_values: withAssignment ? { [input.systemKey]: input.value } : null,
    p_valid_from: input.since || null,
  }
}

/** Neue Person mit Status „aktiv“ ab „seit“ (R4) und erster Zuordnung; Rechte und R3 prüft ea_check_create. */
export async function createVolunteer(input: VolunteerInput): Promise<{ id: string | null; error: unknown }> {
  const { data, error } = await supabase.rpc('ea_create_volunteer', {
    p_first: input.first.trim(),
    p_last: input.last.trim(),
    p_preferred: input.preferred.trim() || null,
    ...assignmentArgs(input),
  })
  if (error) return { id: null, error }
  return { id: data as string, error: null }
}

/** Rückkehr (ausgeschieden) bzw. Übernahme (ohne Ehrenamtsstatus) mit der eingegebenen Zuordnung (US-EA-10). */
export async function activatePerson(personId: string, input: VolunteerInput) {
  const { error } = await supabase.rpc('ea_activate_person', { p_person: personId, ...assignmentArgs(input) })
  return error ?? null
}

// --- Lizenz und Qualifikation: Vorbelegung und Verlängern (US-EA-07; T043, T044)

/** R5: „gültig bis“ aus Qualifikationsart, „gültig von“ und „letzte Fortbildung“; null ohne Gültigkeitsdauer. */
export async function deriveValidUntil(input: {
  qualificationType: string
  validFrom: string
  lastTraining: string | null
}): Promise<string | null> {
  const { data, error } = await supabase.rpc('ea_default_valid_until', {
    p_qualification_type: input.qualificationType,
    p_valid_from: input.validFrom,
    p_last_training: input.lastTraining,
  })
  if (error) throw error
  return (data as string | null) ?? null
}

export type RenewInput = {
  validFrom: string
  lastTraining: string
  validUntil: string
  /** Optional: Fortbildung mit Jahr und Titel anlegen */
  training: { year: number; title: string } | null
}

/** R6: neue Eigenschaft ab „erworben bzw. verlängert am“, die bisherige endet am Vortag (ea_renew_property). */
export async function renewProperty(propertyId: string, input: RenewInput) {
  const fieldValues: Record<string, string> = {}
  if (input.validUntil) fieldValues.valid_until = input.validUntil
  if (input.lastTraining) fieldValues.last_training = input.lastTraining
  const { error } = await supabase.rpc('ea_renew_property', {
    p_property: propertyId,
    p_valid_from: input.validFrom,
    p_field_values: fieldValues,
    p_training: input.training,
  })
  return error ?? null
}

// --- Status ändern und Ausscheiden (US-EA-08, US-EA-09; T045, T046)

/** Referate der Person aus aktuellen Zuordnungen (ea_person_referate, R7). */
export async function loadPersonReferate(personId: string): Promise<Option[] | null> {
  const { data, error } = await supabase.rpc('ea_person_referate', { p_person: personId })
  if (error || !Array.isArray(data)) return null
  return data as Option[]
}

/** aktiv bzw. ruhend (R18, R19); „ausgeschieden“ läuft über leaveVolunteer. */
export async function changeVolunteerStatus(personId: string, status: Exclude<VolunteerStatus, 'left'>, validFrom: string) {
  const { error } = await supabase.rpc('ea_change_volunteer_status', {
    p_person: personId,
    p_status: status,
    p_valid_from: validFrom,
  })
  return error ?? null
}

/** Ausscheiden und Beenden der gewählten Eigenschaften in einer Transaktion (R8, R20). */
export async function leaveVolunteer(personId: string, validFrom: string, endPropertyIds: string[]) {
  const { error } = await supabase.rpc('ea_leave', {
    p_person: personId,
    p_valid_from: validFrom,
    p_end_property_ids: endPropertyIds,
  })
  return error ?? null
}
