// Personen in AD: Übersicht (US-AD-06, US-AD-15; T071, T072), Anlegen und Detail (US-AD-07, US-AD-24, US-AD-25; T074, T075).
// Welche Personen sichtbar sind, entscheidet die RLS (R32); das Frontend filtert nur innerhalb davon.
import { redirect, type LoaderFunctionArgs } from 'react-router-dom'
import { PAGE_SIZE } from '@/components/Pagination'
import type { PropertyField, PropertyType } from '@/features/ad/eigenschaftsarten/data'
import type { QualificationType } from '@/features/ad/qualifikationsarten/data'
import type { SimilarPerson } from '@/features/shared/DublettenDialog'
import type { FieldValues, NamedOption, PropertyInput } from '@/features/shared/Eigenschaftsformular'
import { personName } from '@/lib/format'
import { requireLevel, type AccessStatus } from '@/lib/rights'
import { supabase } from '@/lib/supabase'

export type VolunteerStatus = 'active' | 'dormant' | 'left'
export type PersonKind = 'human' | 'function'

export type PersonRow = {
  person_id: string
  first_name: string
  preferred_name: string | null
  last_name: string
  kind: PersonKind
  created_in: string
  volunteer_status: VolunteerStatus | null
  volunteer_status_since: string | null
  login_email: string | null
  access_status: AccessStatus
  has_group_relation: boolean
  templates: string[]
}

export const VOLUNTEER_STATUS_LABELS: Record<VolunteerStatus, string> = {
  active: 'aktiv',
  dormant: 'ruhend',
  left: 'ausgeschieden',
}

/** Filter „Zugehörigkeit“ (spec.md AD Abschnitt 6 [ANNAHME v0.7], research.md R-28). */
export const MEMBERSHIP_FILTERS = {
  zugang: 'mit Zugang',
  funktionsperson: 'Funktionsperson',
  ehrenamt: 'Ehrenamtsmanagement',
  gruppen: 'nur Gruppen',
  ohne: 'ohne Zugehörigkeit',
} as const

export type MembershipFilter = keyof typeof MEMBERSHIP_FILTERS

export type PersonFilter = {
  q: string
  status: AccessStatus | ''
  membership: MembershipFilter | ''
  page: number
}

export type EmergencyNotice = { count: number; last_at: string | null }

export type OverviewResult = {
  filter: PersonFilter
  rows: PersonRow[]
  total: number
  failed: boolean
  emergency: EmergencyNotice | null
}

export function readFilter(url: URL): PersonFilter {
  const p = url.searchParams
  const status = p.get('status') ?? ''
  const membership = p.get('zugehoerigkeit') ?? ''
  const page = Number.parseInt(p.get('seite') ?? '1', 10)
  return {
    q: (p.get('q') ?? '').trim(),
    status: (['none', 'invited', 'active', 'locked'] as string[]).includes(status) ? (status as AccessStatus) : '',
    membership: membership in MEMBERSHIP_FILTERS ? (membership as MembershipFilter) : '',
    page: Number.isFinite(page) && page > 0 ? page : 1,
  }
}

export function filterHref(filter: PersonFilter, page = filter.page): string {
  const p = new URLSearchParams()
  if (filter.q) p.set('q', filter.q)
  if (filter.status) p.set('status', filter.status)
  if (filter.membership) p.set('zugehoerigkeit', filter.membership)
  if (page > 1) p.set('seite', String(page))
  const s = p.toString()
  return s ? `/ad?${s}` : '/ad'
}

// PostgREST-Filterwerte: Anführungszeichen schützen Kommas und Klammern; eigene Anführungszeichen entfallen
function quote(value: string) {
  return `"${value.replace(/["\\]/g, '')}"`
}

export async function loadPersonOverview({ request }: LoaderFunctionArgs): Promise<OverviewResult> {
  await requireLevel('AD', 'read')
  const filter = readFilter(new URL(request.url))
  const from = (filter.page - 1) * PAGE_SIZE

  let query = supabase
    .from('ad_v_person_overview')
    .select('*', { count: 'exact' })
    .order('last_name')
    .order('first_name')
    .range(from, from + PAGE_SIZE - 1)

  if (filter.q) {
    const like = quote(`%${filter.q}%`)
    query = query.or(`first_name.ilike.${like},preferred_name.ilike.${like},last_name.ilike.${like}`)
  }
  if (filter.status) query = query.eq('access_status', filter.status)
  switch (filter.membership) {
    case 'zugang':
      query = query.neq('access_status', 'none')
      break
    case 'funktionsperson':
      query = query.eq('kind', 'function')
      break
    case 'ehrenamt':
      query = query.not('volunteer_status', 'is', null)
      break
    case 'gruppen':
      query = query.eq('has_group_relation', true).is('volunteer_status', null).eq('access_status', 'none')
      break
    case 'ohne':
      query = query
        .eq('kind', 'human')
        .eq('has_group_relation', false)
        .is('volunteer_status', null)
        .eq('access_status', 'none')
      break
  }

  const [result, emergency] = await Promise.all([query, supabase.rpc('ad_pending_emergency_logins')])

  if (result.error) return { filter, rows: [], total: 0, failed: true, emergency: null }

  const notice = !emergency.error && Array.isArray(emergency.data) && emergency.data.length > 0
    ? (emergency.data[0] as EmergencyNotice)
    : null

  return {
    filter,
    rows: (result.data ?? []) as PersonRow[],
    total: result.count ?? 0,
    failed: false,
    emergency: notice && notice.count > 0 ? notice : null,
  }
}

export async function acknowledgeEmergency() {
  const { error } = await supabase.rpc('ad_acknowledge_emergency')
  return error ?? null
}

// --- Person anlegen und Personendetail (US-AD-07, US-AD-24, US-AD-25; T074, T075)

export type DetailResult = {
  person: PersonRow | null
  properties: PropertiesData | null
  assignments: AssignmentsData | null
  failed: boolean
}

export async function loadPersonDetail({ params }: LoaderFunctionArgs): Promise<DetailResult> {
  await requireLevel('AD', 'read')
  const [person, properties, assignments] = await Promise.all([
    supabase.from('ad_v_person_overview').select('*').eq('person_id', params.id!).maybeSingle(),
    loadPersonProperties(params.id!),
    loadAssignments(params.id!),
  ])
  if (person.error) return { person: null, properties: null, assignments: null, failed: true }
  if (!person.data) throw redirect('/ad')
  return { person: person.data as PersonRow, properties, assignments, failed: false }
}

export type SimilarResult = { hits: SimilarPerson[]; error: unknown }

/** Dublettenprüfung nach R3a/R40 (ad_find_similar_persons); die Datenbank prüft das Recht zum Aufruf. */
export async function findSimilarPersons(first: string, last: string, email: string): Promise<SimilarResult> {
  const { data, error } = await supabase.rpc('ad_find_similar_persons', {
    p_first: first.trim(),
    p_last: last.trim(),
    p_email: email.trim() || null,
  })
  if (error) return { hits: [], error }
  return { hits: (data ?? []) as SimilarPerson[], error: null }
}

export type CreateInput = { first: string; preferred: string; last: string; email: string }
export type CreateResult = { id: string | null; error: unknown }

/**
 * Legt die Person an (Art Mensch, created_in AD) und bei Login-Adresse den Zugang (Status „kein Zugang“).
 * R2 wird vorab geprüft, damit die Person nicht ohne Zugang stehen bleibt; R1 prüft der Trigger (Testdomains in TEST).
 */
export async function createPerson(input: CreateInput): Promise<CreateResult> {
  const email = input.email.trim()
  if (email) {
    const taken = await supabase.from('ad_accesses').select('id').eq('login_email', email).maybeSingle()
    if (taken.error) return { id: null, error: taken.error }
    if (taken.data) return { id: null, error: 'AD_EMAIL_TAKEN' }
  }

  const { data, error } = await supabase
    .from('ea_persons')
    .insert({ first_name: input.first.trim(), last_name: input.last.trim(), preferred_name: input.preferred.trim() || null })
    .select('id')
    .single()
  if (error) return { id: null, error }

  if (email) {
    const access = await supabase.from('ad_accesses').insert({ person_id: data.id, login_email: email })
    if (access.error) return { id: data.id, error: access.error }
  }
  return { id: data.id, error: null }
}

export async function updatePersonName(id: string, input: { first: string; preferred: string; last: string }) {
  const { error } = await supabase
    .from('ea_persons')
    .update({ first_name: input.first.trim(), last_name: input.last.trim(), preferred_name: input.preferred.trim() || null })
    .eq('id', id)
  return error ?? null
}

// --- Eigenschaften einer Person (US-AD-13, US-AD-19, US-AD-22; T083)

export type PropertyTypeWithFields = PropertyType & { fields: PropertyField[] }

export type PropertyHistory = {
  id: number
  field_values: FieldValues
  related_referat_id: string | null
  related_gremium_id: string | null
  valid_from: string
  valid_to: string | null
  changed_at: string
  changed_by: string | null
}

export type PersonProperty = {
  id: string
  person_id: string
  property_type_id: string
  field_values: FieldValues
  related_referat_id: string | null
  related_gremium_id: string | null
  valid_from: string
  valid_to: string | null
  updated_at: string
  updated_by: string | null
  ea_property_history: PropertyHistory[]
}

export type PropertiesData = {
  /** Eigenschaftsarten mit „sichtbar in“ AD, mit Feldern */
  types: PropertyTypeWithFields[]
  properties: PersonProperty[]
  referate: NamedOption[]
  gremien: NamedOption[]
  qualificationTypes: QualificationType[]
  /** Anzeigename je Auth-Nutzer (geändert von) */
  userNames: Record<string, string>
}

const TYPE_COLUMNS =
  'id, name, purpose, category, read_level, relation_kind, relation_required, allow_multiple, system_key, visible_in, origin, valid_from_label, valid_to_label'

// Namen zu Auth-Nutzern über Zugang → Person; nur lesbar, soweit die RLS es erlaubt
async function loadUserNames(userIds: string[]): Promise<Record<string, string>> {
  const ids = [...new Set(userIds.filter(Boolean))]
  if (ids.length === 0) return {}
  const accesses = await supabase.from('ad_accesses').select('auth_user_id, person_id').in('auth_user_id', ids)
  if (accesses.error || accesses.data.length === 0) return {}
  const persons = await supabase
    .from('ea_persons')
    .select('id, first_name, preferred_name, last_name')
    .in('id', accesses.data.map((a) => a.person_id))
  if (persons.error) return {}
  const byPerson = new Map(persons.data.map((p) => [p.id, personName(p)]))
  return Object.fromEntries(
    accesses.data.flatMap((a) => (byPerson.has(a.person_id) ? [[a.auth_user_id as string, byPerson.get(a.person_id)!]] : [])),
  )
}

export async function loadPersonProperties(personId: string): Promise<PropertiesData | null> {
  const [types, properties, referate, gremien, qualificationTypes] = await Promise.all([
    supabase.from('ea_property_types').select(`${TYPE_COLUMNS}, ea_property_fields(*)`).contains('visible_in', ['AD']).order('name'),
    supabase.from('ea_properties').select('*, ea_property_history(*)').eq('person_id', personId).order('valid_from', { ascending: false }),
    supabase.from('ea_referate').select('id, name, is_active').order('sort_order'),
    supabase.from('ea_gremien').select('id, name, is_active').order('sort_order'),
    supabase.from('ad_qualification_types').select('id, code, name, discipline, kind, status').order('name'),
  ])
  if (types.error || properties.error || referate.error || gremien.error || qualificationTypes.error) return null

  const props = properties.data as PersonProperty[]
  const userNames = await loadUserNames([
    ...props.map((p) => p.updated_by ?? ''),
    ...props.flatMap((p) => (p.ea_property_history ?? []).map((h) => h.changed_by ?? '')),
  ])

  return {
    types: (types.data as (PropertyType & { ea_property_fields: PropertyField[] })[]).map(({ ea_property_fields, ...t }) => ({
      ...t,
      fields: [...ea_property_fields].sort((a, b) => a.sort_order - b.sort_order),
    })),
    properties: props,
    referate: referate.data as NamedOption[],
    gremien: gremien.data as NamedOption[],
    qualificationTypes: qualificationTypes.data as QualificationType[],
    userNames,
  }
}

/** Legt eine Eigenschaft an oder ändert sie; Regeln R27, R28, R35, R37, R38 prüft die Datenbank. */
export async function saveProperty(id: string | null, personId: string, typeId: string, input: PropertyInput) {
  const row = {
    field_values: input.field_values,
    related_referat_id: input.related_referat_id,
    related_gremium_id: input.related_gremium_id,
    valid_from: input.valid_from,
    valid_to: input.valid_to,
  }
  const { error } = id
    ? await supabase.from('ea_properties').update(row).eq('id', id)
    : await supabase.from('ea_properties').insert({ ...row, person_id: personId, property_type_id: typeId })
  return error ?? null
}

// --- Rechtevorlagen einer Person (US-AD-11, US-AD-21; T084)

export type TemplateOption = { id: string; name: string; description: string | null; needsReferate: boolean }

export type Assignment = {
  id: string
  template_id: string
  templateName: string
  needsReferate: boolean
  assigned_at: string
  referate: { id: string; name: string }[]
}

export type AssignmentsData = {
  assignments: Assignment[]
  templates: TemplateOption[]
  referate: NamedOption[]
}

export async function loadAssignments(personId: string): Promise<AssignmentsData | null> {
  const [templates, rights, assignments, referate] = await Promise.all([
    supabase.from('ad_templates').select('id, name, description').order('name'),
    supabase.from('ad_template_rights').select('template_id, scope, level').eq('scope', 'referat').neq('level', 'none'),
    supabase
      .from('ad_template_assignments')
      .select('id, template_id, assigned_at, ad_assignment_referate(referat_id, ea_referate(id, name, sort_order))')
      .eq('person_id', personId)
      .is('revoked_at', null),
    supabase.from('ea_referate').select('id, name, is_active').order('sort_order'),
  ])
  if (templates.error || rights.error || assignments.error || referate.error) return null

  const needs = new Set(rights.data.map((r) => r.template_id as string))
  const templateOptions: TemplateOption[] = templates.data.map((t) => ({ ...t, needsReferate: needs.has(t.id) }))
  const byId = new Map(templateOptions.map((t) => [t.id, t]))

  type Row = {
    id: string
    template_id: string
    assigned_at: string
    ad_assignment_referate: { referat_id: string; ea_referate: { id: string; name: string; sort_order: number } | null }[]
  }
  const rows = (assignments.data as unknown as Row[]).map((a) => ({
    id: a.id,
    template_id: a.template_id,
    templateName: byId.get(a.template_id)?.name ?? '–',
    needsReferate: byId.get(a.template_id)?.needsReferate ?? false,
    assigned_at: a.assigned_at,
    referate: a.ad_assignment_referate
      .flatMap((r) => (r.ea_referate ? [r.ea_referate] : []))
      .sort((x, y) => x.sort_order - y.sort_order)
      .map(({ id, name }) => ({ id, name })),
  }))
  rows.sort((a, b) => a.templateName.localeCompare(b.templateName, 'de'))

  return { assignments: rows, templates: templateOptions, referate: referate.data as NamedOption[] }
}

export async function assignTemplate(personId: string, templateId: string, referate: string[]) {
  const { error } = await supabase.rpc('ad_assign_template', {
    p_person: personId,
    p_template: templateId,
    p_referate: referate.length > 0 ? referate : null,
  })
  return error ?? null
}

export async function setAssignmentReferate(assignmentId: string, referate: string[]) {
  const { error } = await supabase.rpc('ad_set_assignment_referate', { p_assignment: assignmentId, p_referate: referate })
  return error ?? null
}

export async function revokeTemplate(personId: string, templateId: string) {
  const { error } = await supabase.rpc('ad_revoke_template', { p_person: personId, p_template: templateId })
  return error ?? null
}
