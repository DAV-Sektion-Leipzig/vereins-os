// Übersicht der Aktiven (US-EA-02, US-EA-03; T034). Welche Personen sichtbar sind, entscheidet die RLS
// (R32 AD); ea_volunteer_list filtert nur innerhalb davon. Filter und Seite stehen in der URL (A5).
import type { LoaderFunctionArgs } from 'react-router-dom'
import { PAGE_SIZE } from '@/components/Pagination'
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
function restrictedReferate(access: EaAccess): string[] | null {
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

async function loadOptions(access: EaAccess): Promise<FilterOptions> {
  const [referate, gremien, types, qualifications] = await Promise.all([
    supabase.from('ea_referate').select('id, name').eq('is_active', true).order('sort_order'),
    access.canManage
      ? supabase.from('ea_gremien').select('id, name').eq('is_active', true).order('sort_order')
      : Promise.resolve({ data: null }),
    supabase
      .from('ea_property_types')
      .select('system_key, ea_property_fields(key, choice_values)')
      .in('system_key', ['function', 'position']),
    supabase.from('ad_qualification_types').select('id, code, name, discipline').order('discipline').order('name'),
  ])

  const own = restrictedReferate(access)
  const allReferate = (referate.data ?? []) as Option[]
  const qualificationTypes = (qualifications.data ?? []) as QualificationOption[]
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
    loadOptions(access),
  ])

  if (list.error || !Array.isArray(list.data)) return { filter, options, rows: [], total: 0, failed: true }
  const rows = list.data as VolunteerRow[]
  return { filter, options, rows, total: rows[0]?.total_count ?? 0, failed: false }
}
